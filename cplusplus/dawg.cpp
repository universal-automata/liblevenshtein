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

#include <algorithm>
#include <sstream>

#include "dawg.h"

namespace levenshtein {
  unsigned long long DawgNode::next_id() {
    static unsigned long long next_id = 0;
    return ++ next_id;
  }

  DawgNode::DawgNode() : id(next_id()) {}
  DawgNode::~DawgNode() {
    for (auto pair : edges) {
      delete pair.second;
    }
  }

  std::string DawgNode::signature() const {
    std::vector<std::string> edges;
    for (auto pair : this->edges) {
      std::stringstream stream;
      stream << pair.first << pair.second->id;
      edges.push_back(stream.str());
    }
    std::sort(edges.begin(), edges.end());
    std::stringstream stream;
    for (auto edge : edges) {
      stream << edge;
    }
    return stream.str();
  }

  Dawg::Dawg(std::vector<std::string> &dictionary) : root(new DawgNode()) {
    for (std::string word : dictionary) {
      insert(word);
    }
    finish();
  }

  Dawg::~Dawg() {
    delete this->root;
  }

  void Dawg::insert(std::string word) {
    size_t i = 0; // find the longest common prefix
    size_t upper = std::min(word.length(), previous_word.length());
    for (; i < upper && word[i] == previous_word[i]; ++i);

    // Check the unchecked_nodes for redundant nodes, proceeding from the leaf
    // up to the longest common prefix.  Then, truncate the list at that point.
    minimize(i);

    // Add the suffix, starting from the correct node mid-way through the graph
    DawgNode *node = unchecked_nodes.size()
      ? std::get<2>(unchecked_nodes.back())
      : root;

    for (; i < word.length(); ++i) {
      const char &edge = word[i];
      DawgNode *next_node = new DawgNode();
      node->edges[edge] = next_node;
      unchecked_nodes.push_back(std::make_tuple(node, edge, next_node));
      node = next_node;
    }

    node->final = true;
    previous_word = word;
  }

  void Dawg::finish() {
    minimize(0);
  }

  void Dawg::minimize(size_t lower) {
    while (unchecked_nodes.size() > lower) {
      DawgNode *parent, *child; char edge;
      std::tie(parent, edge, child) = unchecked_nodes.back();
      unchecked_nodes.pop_back();

      std::string signature = child->signature();

      auto previous = minimized_nodes.find(signature);
      if (previous != minimized_nodes.end()) {
        parent->edges[edge] = previous->second;
        child->edges.erase(child->edges.begin(), child->edges.end());
        delete child;
      }
      else {
        minimized_nodes[signature] = child;
      }
    }
  }

  bool Dawg::accepts(std::string &word) const {
    DawgNode *node = root;

    for (const char &edge : word) {
      auto next = node->edges.find(edge);
      if (next == node->edges.end()) {
        return false;
      }
      node = next->second;
    }

    return node->final;
  }
}
