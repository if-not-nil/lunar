#!/bin/bash

input=$(cat -)

lines=$(echo "$input" | wc -l)
words=$(echo "$input" | wc -w)
chars=$(echo "$input" | wc -m)

echo "lines: $lines"
echo "words: $words"
echo "chars: $chars"
