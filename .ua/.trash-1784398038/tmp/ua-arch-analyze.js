#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

function fail(msg) {
  console.error('ERROR: ' + msg);
  process.exit(1);
}

const inputPath = process.argv[2];
const outputPath = process.argv[3];

if (!inputPath || !outputPath) {
  fail('Usage: node ua-arch-analyze.js <input.json> <output.json>');
}

let data;
try {
  data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
} catch (e) {
  fail('Failed to read/parse input: ' + e.message);
}

const fileNodes = data.fileNodes || [];
const importEdges = data.importEdges || [];
const allEdges = data.allEdges || [];

// ---------------------------------------------------------------------------
// A. Directory Grouping
// ---------------------------------------------------------------------------

function dirOf(filePath) {
  const idx = filePath.lastIndexOf('/');
  return idx === -1 ? '' : filePath.substring(0, idx);
}

// Compute common path prefix (directory-segment aware) shared by all files.
function commonPrefix(paths) {
  if (paths.length === 0) return '';
  const splitPaths = paths.map((p) => p.split('/'));
  let prefixSegs = splitPaths[0].slice(0, -1); // drop filename
  for (let i = 1; i < splitPaths.length; i++) {
    const segs = splitPaths[i].slice(0, -1);
    let j = 0;
    while (j < prefixSegs.length && j < segs.length && prefixSegs[j] === segs[j]) j++;
    prefixSegs = prefixSegs.slice(0, j);
    if (prefixSegs.length === 0) break;
  }
  return prefixSegs.length ? prefixSegs.join('/') + '/' : '';
}

const allPaths = fileNodes.map((n) => n.filePath);
const prefix = commonPrefix(allPaths);

function groupForPath(filePath) {
  let rest = filePath;
  if (prefix && filePath.startsWith(prefix)) {
    rest = filePath.substring(prefix.length);
  }
  const segs = rest.split('/');
  if (segs.length > 1) {
    return segs[0];
  }
  // No subdirectory after prefix -- fall back to first directory segment of
  // the full path, or flat-structure extension-based grouping.
  const fullSegs = filePath.split('/');
  if (fullSegs.length > 1) {
    return fullSegs[0];
  }
  // Flat file at repo root -- group by extension/type pattern.
  const base = fullSegs[0];
  const extMatch = base.match(/\.([a-zA-Z0-9]+)$/);
  if (/\.(test|spec)\./.test(base)) return 'test';
  if (/\.config\./.test(base)) return 'config';
  return extMatch ? '_root_' + extMatch[1] : '_root_other';
}

const directoryGroups = {};
const nodeIdToGroup = {};
for (const node of fileNodes) {
  const group = groupForPath(node.filePath);
  if (!directoryGroups[group]) directoryGroups[group] = [];
  directoryGroups[group].push(node.id);
  nodeIdToGroup[node.id] = group;
}

// ---------------------------------------------------------------------------
// B. Node Type Grouping
// ---------------------------------------------------------------------------

const nodeTypeGroups = {};
for (const node of fileNodes) {
  const t = node.type || 'file';
  if (!nodeTypeGroups[t]) nodeTypeGroups[t] = [];
  nodeTypeGroups[t].push(node.id);
}

// ---------------------------------------------------------------------------
// C. Import Adjacency Matrix (fan-in / fan-out)
// ---------------------------------------------------------------------------

const fileFanOut = {};
const fileFanIn = {};
const groupImportsTo = {}; // group -> Set(group)
const groupImportedByFrom = {}; // group -> Set(group)

for (const edge of importEdges) {
  fileFanOut[edge.source] = (fileFanOut[edge.source] || 0) + 1;
  fileFanIn[edge.target] = (fileFanIn[edge.target] || 0) + 1;

  const sGroup = nodeIdToGroup[edge.source];
  const tGroup = nodeIdToGroup[edge.target];
  if (sGroup && tGroup) {
    if (!groupImportsTo[sGroup]) groupImportsTo[sGroup] = new Set();
    groupImportsTo[sGroup].add(tGroup);
    if (!groupImportedByFrom[tGroup]) groupImportedByFrom[tGroup] = new Set();
    groupImportedByFrom[tGroup].add(sGroup);
  }
}

// ---------------------------------------------------------------------------
// D. Cross-Category Dependency Analysis (using allEdges, non-file node types)
// ---------------------------------------------------------------------------

const idToNode = {};
for (const node of fileNodes) idToNode[node.id] = node;

const crossCategoryCounts = {}; // key: fromType|toType|edgeType -> count
for (const edge of allEdges) {
  const sNode = idToNode[edge.source];
  const tNode = idToNode[edge.target];
  if (!sNode || !tNode) continue;
  const fromType = sNode.type || 'file';
  const toType = tNode.type || 'file';
  if (fromType === 'file' && toType === 'file') continue; // handled elsewhere
  const key = fromType + '|' + toType + '|' + (edge.type || 'related');
  crossCategoryCounts[key] = (crossCategoryCounts[key] || 0) + 1;
}

const crossCategoryEdges = Object.keys(crossCategoryCounts).map((key) => {
  const [fromType, toType, edgeType] = key.split('|');
  return { fromType, toType, edgeType, count: crossCategoryCounts[key] };
});

// ---------------------------------------------------------------------------
// E. Inter-Group Import Frequency
// ---------------------------------------------------------------------------

const interGroupCounts = {}; // "from|to" -> count
for (const edge of importEdges) {
  const sGroup = nodeIdToGroup[edge.source];
  const tGroup = nodeIdToGroup[edge.target];
  if (!sGroup || !tGroup) continue;
  const key = sGroup + '|' + tGroup;
  interGroupCounts[key] = (interGroupCounts[key] || 0) + 1;
}
const interGroupImports = Object.keys(interGroupCounts).map((key) => {
  const [from, to] = key.split('|');
  return { from, to, count: interGroupCounts[key] };
});

// ---------------------------------------------------------------------------
// F. Intra-Group Import Density
// ---------------------------------------------------------------------------

const intraGroupDensity = {};
for (const group of Object.keys(directoryGroups)) {
  let internalEdges = 0;
  let totalEdges = 0;
  for (const edge of importEdges) {
    const sGroup = nodeIdToGroup[edge.source];
    const tGroup = nodeIdToGroup[edge.target];
    if (sGroup !== group && tGroup !== group) continue;
    totalEdges++;
    if (sGroup === group && tGroup === group) internalEdges++;
  }
  intraGroupDensity[group] = {
    internalEdges,
    totalEdges,
    density: totalEdges > 0 ? internalEdges / totalEdges : 0,
  };
}

// ---------------------------------------------------------------------------
// G. Directory Pattern Matching
// ---------------------------------------------------------------------------

const dirPatternTable = [
  { re: /^(routes|api|controllers|endpoints|handlers|controller|routers|blueprints)$/i, label: 'api' },
  { re: /^(services|core|lib|domain|logic|internal|composables|signals)$/i, label: 'service' },
  { re: /^(models|db|data|persistence|repository|entities|entity|migrations|sql|database|schema)$/i, label: 'data' },
  { re: /^(components|views|pages|ui|layouts|screens)$/i, label: 'ui' },
  { re: /^(middleware|plugins|interceptors|guards)$/i, label: 'middleware' },
  { re: /^(utils|helpers|common|shared|tools|pkg|templatetags)$/i, label: 'utility' },
  { re: /^(config|constants|env|settings|management|commands)$/i, label: 'config' },
  { re: /^(__tests__|test|tests|spec|specs)$/i, label: 'test' },
  { re: /^(types|interfaces|schemas|contracts|dtos|dto|request|response)$/i, label: 'types' },
  { re: /^(hooks)$/i, label: 'hooks' },
  { re: /^(store|state|reducers|actions|slices)$/i, label: 'state' },
  { re: /^(assets|static|public)$/i, label: 'assets' },
  { re: /^(serializers)$/i, label: 'api' },
  { re: /^(cmd|bin)$/i, label: 'entry' },
  { re: /^(mailers|jobs|channels)$/i, label: 'service' },
  { re: /^(docs|documentation|wiki)$/i, label: 'documentation' },
  { re: /^(deploy|deployment|infra|infrastructure)$/i, label: 'infrastructure' },
  { re: /^(\.github|\.gitlab|\.circleci)$/i, label: 'ci-cd' },
  { re: /^(k8s|kubernetes|helm|charts)$/i, label: 'infrastructure' },
  { re: /^(terraform|tf)$/i, label: 'infrastructure' },
  { re: /^(docker)$/i, label: 'infrastructure' },
];

function patternForGroup(groupName) {
  for (const entry of dirPatternTable) {
    if (entry.re.test(groupName)) return entry.label;
  }
  return null;
}

const patternMatches = {};
for (const group of Object.keys(directoryGroups)) {
  const label = patternForGroup(group);
  if (label) patternMatches[group] = label;
}

// ---------------------------------------------------------------------------
// H. Deployment Topology Detection
// ---------------------------------------------------------------------------

const infraFiles = [];
let hasDockerfile = false;
let hasCompose = false;
let hasK8s = false;
let hasTerraform = false;
let hasCI = false;

for (const node of fileNodes) {
  const base = path.basename(node.filePath);
  const fp = node.filePath;
  if (/^Dockerfile/.test(base)) { hasDockerfile = true; infraFiles.push(fp); }
  if (/^docker-compose/.test(base)) { hasCompose = true; infraFiles.push(fp); }
  if (/\.ya?ml$/.test(base) && /k8s|kubernetes/i.test(fp)) { hasK8s = true; infraFiles.push(fp); }
  if (/\.tf$|\.tfvars$/.test(base)) { hasTerraform = true; infraFiles.push(fp); }
  if (/^\.github\/workflows\//.test(fp) || /\.gitlab-ci\.yml$/.test(base) || base === 'Jenkinsfile') {
    hasCI = true; infraFiles.push(fp);
  }
  if (base === 'Makefile') { infraFiles.push(fp); }
}

const deploymentTopology = {
  hasDockerfile,
  hasCompose,
  hasK8s,
  hasTerraform,
  hasCI,
  infraFiles: Array.from(new Set(infraFiles)),
};

// ---------------------------------------------------------------------------
// I. Data Pipeline Detection
// ---------------------------------------------------------------------------

const schemaFiles = [];
const migrationFiles = [];
const dataModelFiles = [];
const apiHandlerFiles = [];

for (const node of fileNodes) {
  const fp = node.filePath;
  const base = path.basename(fp);
  if (/\.sql$/.test(base) || /\.graphql$|\.proto$/.test(base)) schemaFiles.push(fp);
  if (/migrations\//.test(fp)) migrationFiles.push(fp);
  const group = nodeIdToGroup[node.id];
  if (patternMatches[group] === 'data') dataModelFiles.push(fp);
  if (patternMatches[group] === 'api') apiHandlerFiles.push(fp);
}

const dataPipeline = {
  schemaFiles,
  migrationFiles,
  dataModelFiles,
  apiHandlerFiles,
};

// ---------------------------------------------------------------------------
// J. Documentation Coverage
// ---------------------------------------------------------------------------

const groupsWithDocs = new Set();
for (const node of fileNodes) {
  if (node.type === 'document' || /\.md$/i.test(node.filePath)) {
    groupsWithDocs.add(nodeIdToGroup[node.id]);
  }
}
const totalGroups = Object.keys(directoryGroups).length;
const docCoverage = {
  groupsWithDocs: groupsWithDocs.size,
  totalGroups,
  coverageRatio: totalGroups > 0 ? groupsWithDocs.size / totalGroups : 0,
  undocumentedGroups: Object.keys(directoryGroups).filter((g) => !groupsWithDocs.has(g)),
};

// ---------------------------------------------------------------------------
// K. Dependency Direction
// ---------------------------------------------------------------------------

const dependencyDirection = [];
const seenPairs = new Set();
for (const key of Object.keys(interGroupCounts)) {
  const [a, b] = key.split('|');
  if (a === b) continue;
  const pairKey = [a, b].sort().join('|');
  if (seenPairs.has(pairKey)) continue;
  seenPairs.add(pairKey);
  const aToB = interGroupCounts[a + '|' + b] || 0;
  const bToA = interGroupCounts[b + '|' + a] || 0;
  if (aToB > bToA) dependencyDirection.push({ dependent: a, dependsOn: b });
  else if (bToA > aToB) dependencyDirection.push({ dependent: b, dependsOn: a });
}

// ---------------------------------------------------------------------------
// File Stats
// ---------------------------------------------------------------------------

const filesPerGroup = {};
for (const group of Object.keys(directoryGroups)) filesPerGroup[group] = directoryGroups[group].length;

const nodeTypeCounts = {};
for (const t of Object.keys(nodeTypeGroups)) nodeTypeCounts[t] = nodeTypeGroups[t].length;

const fileStats = {
  totalFileNodes: fileNodes.length,
  filesPerGroup,
  nodeTypeCounts,
};

// ---------------------------------------------------------------------------
// Assemble Output
// ---------------------------------------------------------------------------

// Convert Set-valued group import maps into plain arrays for JSON output.
const groupImportsToPlain = {};
for (const g of Object.keys(groupImportsTo)) groupImportsToPlain[g] = Array.from(groupImportsTo[g]);
const groupImportedByFromPlain = {};
for (const g of Object.keys(groupImportedByFrom)) groupImportedByFromPlain[g] = Array.from(groupImportedByFrom[g]);

const result = {
  scriptCompleted: true,
  commonPrefix: prefix,
  directoryGroups,
  nodeTypeGroups,
  crossCategoryEdges,
  interGroupImports,
  intraGroupDensity,
  patternMatches,
  deploymentTopology,
  dataPipeline,
  docCoverage,
  dependencyDirection,
  fileStats,
  fileFanIn,
  fileFanOut,
  groupImportsTo: groupImportsToPlain,
  groupImportedByFrom: groupImportedByFromPlain,
};

try {
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2));
} catch (e) {
  fail('Failed to write output: ' + e.message);
}

console.log('OK: wrote ' + outputPath);
process.exit(0);
