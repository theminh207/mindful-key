//
//  MoodBuffer.cpp
//  OpenKey
//
//  [MINDFUL] Shared C++ buffer for collecting committed words.
//

#include "MoodBuffer.h"

MoodBuffer::MoodBuffer(size_t maxWords)
: _maxWords(maxWords == 0 ? 1 : maxWords) {
}

void MoodBuffer::pushWord(const std::wstring& word) {
    if (word.empty())
        return;

    _words.push_back(word);
    while (_words.size() > _maxWords)
        _words.erase(_words.begin());
}

std::wstring MoodBuffer::recentText() const {
    std::wstring text;
    for (size_t i = 0; i < _words.size(); i++) {
        if (!text.empty())
            text += L" ";
        text += _words[i];
    }
    return text;
}

void MoodBuffer::clear() {
    _words.clear();
}

bool MoodBuffer::empty() const {
    return _words.empty();
}
