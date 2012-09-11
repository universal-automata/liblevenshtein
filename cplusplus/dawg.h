// Copyright (c) 2012 Dylon Edwards
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef __LEVENSHTEIN__DAWG__H__
#define __LEVENSHTEIN__DAWG__H__

#include <vector>
#include <string>
#include <map>
#include <unordered_map>
#include <tuple>

namespace levenshtein {

  // ===========================================================================
  // Taken and modified for my purposes from the following source:
  //  o http://stevehanov.ca/blog/index.php?id=115
  // ===========================================================================
  //
  // This class represents a node in the directed acyclic word graph (DAWG,
  // a.k.a.  Minimal Acyclic Finite State Automaton, or MA-FSA).  It has a list
  // of edges to other nodes.  It has functions for testing whether it is
  // equivalent to another node.  Nodes are equivalent if they have identical
  // edges, and each identical edge leads to identical states.
  class DawgNode {
    public:
      DawgNode();
      ~DawgNode();

      std::map<const char, DawgNode *> edges;
      bool final = false;

      std::string signature() const;
    private:
      static unsigned long long next_id();
      const unsigned long long id;
  };

  class Dawg {
    public:
      Dawg(std::vector<std::string> &dictionary);
      ~Dawg();

      DawgNode *root;

      void insert(std::string word);
      void finish();
      void minimize(size_t lower);
      bool accepts(std::string &word) const;
    private:
      std::string previous_word = "";
      std::vector<std::tuple<DawgNode*, char, DawgNode*>> unchecked_nodes;
      std::unordered_map<std::string, DawgNode*> minimized_nodes;
  };
}

#endif
