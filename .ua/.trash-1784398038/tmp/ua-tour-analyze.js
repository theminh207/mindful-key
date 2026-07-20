#!/usr/bin/env node
'use strict';

const fs = require('fs');

function fail(msg) {
  console.error('ERROR:', msg);
  process.exit(1);
}

const inputPath = process.argv[2];
const outputPath = process.argv[3];

if (!inputPath || !outputPath) {
  fail('Usage: node ua-tour-analyze.js <input.json> <output.json>');
}

let raw;
try {
  raw = fs.readFileSync(inputPath, 'utf8');
} catch (e) {
  fail('Could not read input file: ' + e.message);
}

let data;
try {
  data = JSON.parse(raw);
} catch (e) {
  fail('Could not parse input JSON: ' + e.message);
}

const nodes = Array.isArray(data.nodes) ? data.nodes : [];
const edges = Array.isArray(data.edges) ? data.edges : [];
const layers = Array.isArray(data.layers) ? data.layers : [];

if (nodes.length === 0) {
  fail('No nodes found in input data');
}

const nodeById = new Map();
nodes.forEach((n) => nodeById.set(n.id, n));

// --- A. Fan-In Ranking ---
const fanIn = new Map();
nodes.forEach((n) => fanIn.set(n.id, 0));
edges.forEach((e) => {
  if (fanIn.has(e.target)) {
    fanIn.set(e.target, fanIn.get(e.target) + 1);
  }
});
const fanInRanking = [...fanIn.entries()]
  .map(([id, count]) => ({ id, fanIn: count, name: nodeById.get(id) ? nodeById.get(id).name : id }))
  .sort((a, b) => b.fanIn - a.fanIn)
  .slice(0, 20);

// --- B. Fan-Out Ranking ---
const fanOut = new Map();
nodes.forEach((n) => fanOut.set(n.id, 0));
edges.forEach((e) => {
  if (fanOut.has(e.source)) {
    fanOut.set(e.source, fanOut.get(e.source) + 1);
  }
});
const fanOutRanking = [...fanOut.entries()]
  .map(([id, count]) => ({ id, fanOut: count, name: nodeById.get(id) ? nodeById.get(id).name : id }))
  .sort((a, b) => b.fanOut - a.fanOut)
  .slice(0, 20);

// --- C. Entry Point Candidates ---
const ENTRY_FILENAMES = new Set([
  'index.ts', 'index.js', 'main.ts', 'main.js', 'app.ts', 'app.js', 'server.ts', 'server.js',
  'mod.rs', 'main.go', 'main.py', 'main.rs', 'manage.py', 'app.py', 'wsgi.py', 'asgi.py',
  'run.py', '__main__.py', 'Application.java', 'Main.java', 'Program.cs', 'config.ru',
  'index.php', 'App.swift', 'Application.kt', 'main.cpp', 'main.c',
]);

const fanOutValues = [...fanOut.values()].sort((a, b) => a - b);
const fanInValues = [...fanIn.values()].sort((a, b) => a - b);

function percentileThreshold(sortedValues, percentile) {
  if (sortedValues.length === 0) return 0;
  const idx = Math.floor(sortedValues.length * percentile);
  return sortedValues[Math.min(idx, sortedValues.length - 1)];
}

// top 10% fan-out threshold (value at 90th percentile)
const fanOutTop10Threshold = percentileThreshold(fanOutValues, 0.9);
// bottom 25% fan-in threshold (value at 25th percentile)
const fanInBottom25Threshold = percentileThreshold(fanInValues, 0.25);

function pathDepth(filePath) {
  return filePath.split('/').filter(Boolean).length;
}

const entryScores = [];
nodes.forEach((n) => {
  let score = 0;
  const fp = n.filePath || '';
  const base = fp.split('/').pop() || n.name || '';

  if (n.type === 'document') {
    if (base.toLowerCase() === 'readme.md' && pathDepth(fp) <= 1) {
      score += 5;
    } else if (/\.md$/i.test(base) && pathDepth(fp) <= 1) {
      score += 2;
    }
  } else {
    // code / config / other file-like nodes
    if (ENTRY_FILENAMES.has(base)) {
      score += 3;
    }
    if (pathDepth(fp) <= 2) {
      score += 1;
    }
    if ((fanOut.get(n.id) || 0) >= fanOutTop10Threshold && (fanOut.get(n.id) || 0) > 0) {
      score += 1;
    }
    if ((fanIn.get(n.id) || 0) <= fanInBottom25Threshold) {
      score += 1;
    }
  }

  if (score > 0) {
    entryScores.push({ id: n.id, score, name: n.name, summary: n.summary });
  }
});

const entryPointCandidates = entryScores
  .sort((a, b) => b.score - a.score)
  .slice(0, 5);

// --- D. BFS Traversal ---
// pick top CODE entry point (non-document) for BFS start
const topCodeEntry = entryScores
  .filter((c) => {
    const n = nodeById.get(c.id);
    return n && n.type !== 'document';
  })
  .sort((a, b) => b.score - a.score)[0];

const adjacency = new Map();
nodes.forEach((n) => adjacency.set(n.id, []));
edges.forEach((e) => {
  if ((e.type === 'imports' || e.type === 'calls') && adjacency.has(e.source)) {
    adjacency.get(e.source).push(e.target);
  }
});

const bfsTraversal = { startNode: null, order: [], depthMap: {}, byDepth: {} };

if (topCodeEntry) {
  const startId = topCodeEntry.id;
  bfsTraversal.startNode = startId;
  const visited = new Set([startId]);
  const queue = [[startId, 0]];
  bfsTraversal.order.push(startId);
  bfsTraversal.depthMap[startId] = 0;
  bfsTraversal.byDepth['0'] = [startId];

  while (queue.length > 0) {
    const [curId, depth] = queue.shift();
    const neighbors = adjacency.get(curId) || [];
    for (const neighborId of neighbors) {
      if (!visited.has(neighborId) && nodeById.has(neighborId)) {
        visited.add(neighborId);
        const d = depth + 1;
        bfsTraversal.order.push(neighborId);
        bfsTraversal.depthMap[neighborId] = d;
        if (!bfsTraversal.byDepth[String(d)]) bfsTraversal.byDepth[String(d)] = [];
        bfsTraversal.byDepth[String(d)].push(neighborId);
        queue.push([neighborId, d]);
      }
    }
  }
}

// --- E. Non-Code File Inventory ---
const nonCodeFiles = {
  documentation: [],
  infrastructure: [],
  data: [],
  config: [],
};

nodes.forEach((n) => {
  if (n.type === 'document') {
    nonCodeFiles.documentation.push({ id: n.id, name: n.name, type: n.type, summary: n.summary });
  } else if (n.type === 'service' || n.type === 'pipeline' || n.type === 'resource') {
    nonCodeFiles.infrastructure.push({ id: n.id, name: n.name, type: n.type, summary: n.summary });
  } else if (n.type === 'table' || n.type === 'schema' || n.type === 'endpoint') {
    nonCodeFiles.data.push({ id: n.id, name: n.name, type: n.type, summary: n.summary });
  } else if (n.type === 'config') {
    nonCodeFiles.config.push({ id: n.id, name: n.name, type: n.type, summary: n.summary });
  }
});

// --- F. Tightly Coupled Clusters ---
const edgeSet = new Set();
edges.forEach((e) => edgeSet.add(e.source + '|||' + e.target));

function hasEdge(a, b) {
  return edgeSet.has(a + '|||' + b);
}

const bidirectionalPairs = [];
const seenPairs = new Set();
edges.forEach((e) => {
  if (e.source === e.target) return;
  if (e.type !== 'imports' && e.type !== 'calls') return;
  const pairKey = [e.source, e.target].sort().join('|||');
  if (seenPairs.has(pairKey)) return;
  if (hasEdge(e.target, e.source)) {
    seenPairs.add(pairKey);
    bidirectionalPairs.push([e.source, e.target]);
  }
});

// Union-Find to merge overlapping bidirectional pairs into base clusters
const parent = new Map();
function find(x) {
  if (!parent.has(x)) parent.set(x, x);
  if (parent.get(x) !== x) parent.set(x, find(parent.get(x)));
  return parent.get(x);
}
function union(a, b) {
  const ra = find(a);
  const rb = find(b);
  if (ra !== rb) parent.set(ra, rb);
}
bidirectionalPairs.forEach(([a, b]) => union(a, b));

const clusterGroups = new Map();
bidirectionalPairs.forEach(([a, b]) => {
  const root = find(a);
  if (!clusterGroups.has(root)) clusterGroups.set(root, new Set());
  clusterGroups.get(root).add(a);
  clusterGroups.get(root).add(b);
});

// Expand clusters: add nodes connecting to 2+ existing cluster members, cap size at 5
function countConnectionsToCluster(nodeId, clusterSet) {
  let count = 0;
  edges.forEach((e) => {
    if (e.source === nodeId && clusterSet.has(e.target)) count += 1;
    if (e.target === nodeId && clusterSet.has(e.source)) count += 1;
  });
  return count;
}

const clusters = [];
for (const [, memberSet] of clusterGroups.entries()) {
  let members = new Set(memberSet);
  // try expansion up to size 5
  let expanded = true;
  while (members.size < 5 && expanded) {
    expanded = false;
    for (const n of nodes) {
      if (members.has(n.id)) continue;
      if (members.size >= 5) break;
      const connections = countConnectionsToCluster(n.id, members);
      if (connections >= 2) {
        members.add(n.id);
        expanded = true;
      }
    }
  }
  const memberArr = [...members].slice(0, 5);
  let edgeCount = 0;
  edges.forEach((e) => {
    if (memberArr.includes(e.source) && memberArr.includes(e.target)) edgeCount += 1;
  });
  clusters.push({ nodes: memberArr, edgeCount });
}

clusters.sort((a, b) => b.edgeCount - a.edgeCount);
const topClusters = clusters.slice(0, 10);

// --- G. Layer List ---
const layerList = {
  count: layers.length,
  list: layers.map((l) => ({ id: l.id, name: l.name, description: l.description })),
};

// --- H. Node Summary Index ---
const nodeSummaryIndex = {};
nodes.forEach((n) => {
  nodeSummaryIndex[n.id] = { name: n.name, type: n.type, summary: n.summary };
});

const result = {
  scriptCompleted: true,
  entryPointCandidates,
  fanInRanking,
  fanOutRanking,
  bfsTraversal,
  nonCodeFiles,
  clusters: topClusters,
  layers: layerList,
  nodeSummaryIndex,
  totalNodes: nodes.length,
  totalEdges: edges.length,
};

try {
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2));
} catch (e) {
  fail('Could not write output file: ' + e.message);
}

console.log('Analysis complete. Wrote results to', outputPath);
process.exit(0);
