//
//  MoodBuffer.h
//  OpenKey
//
//  [MINDFUL] Shared C++ buffer for collecting committed words.
//  This file is platform-neutral; Win/macOS shells decide how to analyze
//  and display mindfulness prompts.
//

#ifndef MoodBuffer_h
#define MoodBuffer_h

#include <string>
#include <vector>

class MoodBuffer {
public:
    explicit MoodBuffer(size_t maxWords = 15);

    void pushWord(const std::wstring& word);
    std::wstring recentText() const;
    void clear();
    bool empty() const;

private:
    size_t _maxWords;
    std::vector<std::wstring> _words;
};

#endif /* MoodBuffer_h */
