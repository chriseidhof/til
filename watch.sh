#!/bin/bash

fswatch -o . | while read; do clear; jj status; done
