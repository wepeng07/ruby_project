# Homework Assignment 4

## Learning Outcomes

After completion of this assignment, you should be able to:

- work with regular expressions in Ruby.

- do file management in Ruby.

- write automated tests in Ruby.

## Getting Started

To complete this homework assignment, you will need Ruby3. Install it from [here](https://www.ruby-lang.org/en/documentation/installation/) if you do not already have it. You can also find instructions to install Ruby in the lecture notes from the first lecture on Ruby. You will also need to install [Rspec](https://relishapp.com/rspec/docs/gettingstarted) to write and run automated tests.

Download or clone this repository to your local system. Use the following command:

`$ git clone <ssh-link>`

After you clone, you will see a directory of the form *cise337-hw4-ruby-\<username\>*, where *username* is your GitHub username.

In this directory, you will find *src* and *tests* directories. The *src* file will contain all source code files needed to implement the script. It already has some starter code in *src/rugrep.rb*, which contains the method *parseArgs()*. This method should return a string that gets printed by the script. The script *src/rugrep.rb* takes command line arguments that will be captured in the array [ARGF.argv](https://ruby-doc.org/core-2.5.0/ARGF.html#method-i-argv). You can add other Ruby source files to the *src* directory if needed.

The *tests* directory contains Rspec tests to verify the correctness of the implementation. You are expected to write the tests.

## Problem Statement

We will write a Ruby script called **rugrep.rb** to search for patterns in a file. The script should print lines that match the pattern. This is similar to the *grep* utility found in UNIX but we will customize it to suit our needs in this assignment.


To run the script, a user has to type the following command:

`$ ruby rugrep.rb [OPTION ...] ["PATTERN"...] [FILE...]`

As shown, the script **rugrep.rb** takes 3 command-line arguments:

- A list of optional arguments as indicated by `[OPTION ...]`.

- A list of ruby regular expressions in double quotes as indicated by `["PATTERN"]...`.

- A list of file paths as indicated by `[FILE...]`.

The semantics of each of the arguments is described in later sections.

The order of the arguments may not be the same as listed above. An example order of arguments is patterns, followed by options, and then files. Other orders are possible, except all patterns should appear together one after the other. Options and file paths may not appear together.

### Pattern Argument

The pattern argument is a list of one or more arguments. It's a collection of double-quoted ruby regular expressions separated by one or more whitespaces.

For a list of patterns "p1" "p2" ... "pN" provided as arguments to *rugrep*, it prints a line if the line matches at least one of the provided patterns.  

If the user inputs an ill-formed Ruby regex then print the message "Error: cannot parse regex" for that regex. The script processes other regexes if any and prints their results. Error messages (if any) should be printed before printing results for valid regexes.

### File Argument

Users can provide one or more file paths separated by one or more whitespaces. The script prints lines that match the given patterns in each file. Each matched line should be pre-fixed with the relative file path followed by the character **:**. E.g., `path/to/input1.txt: A line in input1.txt`. The prefix is not printed if only one file is provided as an argument. If an IO error occurs when reading a file F then the script processes the other files (if any) and prints the message "Error: could not read file #{relative_filepath}" for the file F. The error messages should be printed first before printing the results from files without errors.  

### Optional Argument

In the absence of options, the script prints lines in all files that match the given pattern/s.

Following are the options that can be provided as arguments:

1. `-v`, `--invert-match`

    Prints lines that do not match the given pattern/s. Each line in a new line.

2. `-c`, `--count`

    Prints the no. of lines that match the given pattern/s. Each line in a new line. If combined with `-v` then return the no. of non-matching lines.

    In case of multiple files prefix the count with the relative file path. E.g.,

    ```
    path/to/file1.txt: 1
    path/to/file2.txt: 0
    path/to/file3.txt: 4
    ```

    The prefix is not printed in case of one file.

3. `-l`, `--files-with-matches`

    Prints all file names that contain lines that match the given pattern/s. Each file name in a new line.

4. `-L`, `--files-without-match`

    Prints the file names that do not contain any line that match the given pattern/s. Each file name in a new line.

5.  `-o`, `--only-matching`

    Prints ALL matches in a matching line. Only prints the matches not the line itself. Each match on a new line. When combined with `-c` prints the no. of lines that match the given pattern/s.

6. `-F`, `--fixed-strings`

    Interprets the patterns as fixed strings and not regular expressions. Prints lines that contain the fixed string. When combined with `-c` prints the no. of lines that contain the fixed strings. When combined with `-o` prints all matches in a matching line. Each match on a new line. When combined with with `-v` prints all lines that do not contain the fixed string. When combined with `-v` and `-c` prints the no. of lines that do not contain the fixed strings.

7. `-A_NUM`, `--after-context=num`

    Prints `NUM` lines that appear after a line in a file that matches the given pattern/s including the matched line. E.g., if `NUM` is 2 then prints a matched line followed by 2 lines that appear after the matched line in the file. If several lines match then place a separator `--` (on a new line) between the groups.

    When combined with `-v` prints a line that does not match the given pattern/s in a file F along with `NUM` lines that appear after that line in F. If several lines do not match then place a separator `--` (on a new line) between the groups.

    When processing more than one file, the script prints the prefix relative path `/path/to/file:` before every line. The prefix is not printed when processing one file.

8. `-B_NUM`, `--after-context=num`

    Prints `NUM` lines that appear before a line in a file that matches the given pattern/s including the matched line. E.g., if `NUM` is 2 then prints a matched line followed by 2 lines that appear before the matched line in the file. If several lines match then place a separator `--` (on a new line) between the groups.

    When combined with `-v` prints a line that does not match the given pattern/s in a file F along with `NUM` lines that appear before that line in F. If several lines do not match then place a separator `--` (on a new line) between the groups.

    When processing more than one file, the script prints the prefix relative path `/path/to/file:` before every line. The prefix is not printed when processing one file.

9. `-C_NUM`, `--context=num`

    Prints `NUM` lines that appear before and after a line in a file that matches the given pattern/s including the matched line. E.g., if `NUM` is 2 then prints a matched line followed by 2 lines that appear before and 2 lines after the matched line in the file. If several lines match then place a separator `--` (on a new line) between the groups.

    When combined with `-v` prints a line that does not match the given pattern/s in a file F along with `NUM` lines that appear before and after that line in F. If several lines do not match then place a separator `--` (on a new line) between the groups.

    When processing more than one file, the script prints the prefix relative path `/path/to/file:` before every line. The prefix is not printed when processing one file.

### Errors

The script prints the message "USAGE: ruby rgrep.rb <OPTIONS> <PATTERNS> <FILES>" and exits if the user enters unexpected arguments. Print the exact message. Unexpected argument scenarios are as follows:

- less than 2 arguments.
- patterns are not contiguously placed, i.e., if a list of patterns are provided as arguments they must occur one after the other in the arguments.
- invalid option names, i.e., option names not listed above.
- invalid option combinations, i.e., option combinations not listed above.
- no patterns are provided as arguments.

## Tesing and Coverage

You are expected to write automated tests to verify the correctness of the scripts in *src*. Tests should be written in Rspec in the *tests* directory. You should run the tests from the project directory using the command `$ rspec tests/rugrep_spec.rb`. Before running Rspec you may to need to initialize it in the project directory. The configuration already exist in this directory. In case they don't run `$ rspec --init` before running the tests with rspec.

You can measure coverage of your test suite with the [simplecov](https://github.com/simplecov-ruby/simplecov) library. You will need to install it using `$ gem install simplecov`.

## Grading

You are expected to write the implementation and test scripts to verify the correctness of your implementations. You will earn 25\% of the credit, if your implementations passes all checks w.r.t to the tests you defined. You will earn an additional 25\% if your tests have a coverage of 95\% or more. The remaining 50\% will be based on the graders' tests. You will get credit for each passing test.

**Remember to submit your GitHub username to Brightspace under Assignment 4 as a comment**. Without this your work may not be graded.

## Submitting Code to GitHub

To submit a file to the remote repository, you first need to add it to the local git repository in your system, that is, directory where you cloned the remote repository initially. Use following commands from your terminal:

`$ cd /path/to/cise337-hw4-ruby-<username>` (skip if you are already in this directory)

```
$ git add src
$ git add tests
```

To submit your work to the remote GitHub repository, you will need to commit the file (with a message) and push the file to the repository. Use the following commands:

`$ git commit -m "<your-custom-message>"`

`$ git push`

## References

- [Ruby Documentation](https://ruby-doc.org/core-3.0.1/)
- [Rspec Documentation](https://relishapp.com/rspec)
- [SimpleCov](https://github.com/simplecov-ruby/simplecov)
