#!/usr/bin/env bats

setup() {
  mkdir test
  ./lit.sh lit.sh.md
}

teardown() {
  rm -rf test
}

@test "live compilation script should match Markdown source" {
  git checkout lit.sh
  pre="$(less test/lit.sh)"
  ./lit.sh lit.sh.md
  post="$(less test/lit.sh)"
  [ "${pre}" == "${post}" ]
}

@test "should not compile files that end in .md without a double extension" {
  touch test/README.md
  ./lit.sh "./test/*"
  count="$(find test -type f | wc -l)"
  [ "${count}" -eq 1 ]
}

@test "should not compile files that end in a single file extension" {
  touch test/script.py
  touch test/script.js
  ./lit.sh "./test/*"
  count="$(find test -type f | wc -l)"
  [ "${count}" -eq 2 ]
}

@test "should not compile non-Markdown files that end in a double file extension" {
  touch test/script.py.js
  ./lit.sh "./test/*"
  count="$(find test -type f | wc -l)"
  [ "${count}" -eq 1 ]
}

@test "should compile Markdown files that end in a double file extension" {
  touch test/script.py.md
  ./lit.sh "./test/*"
  count="$(find test -type f | wc -l)"
  [ "${count}" -eq 2 ]
}

@test "should preserve original file extensions in output filenames" {
  touch test/script.py.md
  ./lit.sh "./test/*"
  new_file="$([ -e test/script.py ])"
  [ new_file ]
}

@test "should compile multiple files" {
  touch test/first.py.md
  touch test/second.py.md
  ./lit.sh "./test/*"
  count="$(find test -type f | wc -l)"
  [ "${count}" -eq 4 ]
}

@test "should select files to compile based on a file glob" {
  touch test/first.py.md
  touch test/second.py.md
  touch test/third.js.md
  ./lit.sh "./test/*.py.md"
  count="$(find test -type f | wc -l)"
  [ "${count}" -eq 5 ]
}

@test "should remove Markdown and preserve code" {
  markdown=$'# a heading\nsome text\n```\nsome code\n```'
  printf "${markdown}" >> test/script.py.md
  ./lit.sh ./test/script.py.md
  code="$(less ./test/script.py)"
  [ "${code}" == "some code" ]
}

@test "should allow language annotation after backticks" {
  markdown=$'# a heading\nsome text\n```javascript\nsome code\n```'
  printf "${markdown}" >> test/script.py.md
  ./lit.sh ./test/script.py.md
  code="$(less ./test/script.py)"
  [ "${code}" == "some code" ]
}

@test "should compile multiple fenced code blocks" {
  first=$'# a heading\nsome text\n```\nsome code\n```'
  second=$'# a heading\nsome text\n```\nsome more code\n```'
  expected=$'some code\nsome more code'
  printf "${first}" >> test/script.py.md
  printf "${second}" >> test/script.py.md
  ./lit.sh ./test/script.py.md
  code="$(less ./test/script.py)"
  [ "${code}" == "${expected}" ]
}