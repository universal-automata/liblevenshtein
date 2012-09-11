#!/usr/bin/env python
# encoding: utf-8

VERSION = '0.0.1'
APPNAME = 'levenshtein'

top = '.'
out = '.'

def options(self):
	self.load('compiler_cxx')

def configure(self):
	self.load('compiler_cxx')
	self.env.CXXFLAGS = [
		'-O4',
		'-std=c++11',
		'-mtune=native',
		'-pipe',
		'-march=corei7-avx'
	]

def build(self):
	self(
			features = 'cxx cxxprogram',
			source   = 'dawg.cpp main.cpp',
			target   = 'dawg',
			includes = '.')

