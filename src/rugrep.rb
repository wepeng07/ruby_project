#!/usr/bin/env ruby
args = ARGF.argv
class ParseError < StandardError; end

class PatternError < StandardError; end

SUPPORT_ARGS = {
  '-v' => '--invert-match',
  '-c' => '--count',
  '-l' => '--files-with-matches',
  '-L' => '--files-without-match',
  '-o' => '--only-matching',
  '-F' => '--fixed-strings',
  '-A' => '--after-context',
  '-B' => '--before-context',
  '-C' => '--context',
}

SUPPORT_MULT_ARGS = %[v c l L o F A Av B Bv C Cv cv co Fc Fo Fv Fcv]
# args = ARGV
def parseArgs(args)
  raise ParseError, 'less than 2 arguments.' if args.length < 2

  options  = {}
  patterns = []
  files    = []

  args.each do |arg|
    begin
      if arg.start_with?('-') || arg.start_with?('--')
        options.merge! parse_options(arg)
      elsif arg.start_with?('/') # pattern
        raise ParseError, 'patterns are not contiguously placed.' unless patterns.empty?

        patterns = parse_pattern(arg)
      elsif arg.match?(/\.\w+$/)
        file = parse_file(arg)
        next if file.nil?
        next if files.find { |efile| efile.path == file.path }

        files.push(file)
      else
        raise ParseError, "not support arg #{arg}"
      end
    end
  end

  raise ParseError, 'no patterns are provided as arguments.' if patterns.empty?
  unless options.keys.empty?
    raise ParseError, 'invalid option combinations.' unless SUPPORT_MULT_ARGS.include?(mult_arg(options))
  end

  [options, patterns, files]
rescue ParseError => e
  puts e.message
end

def mult_arg(options)
  options.keys.sort.join
end

def parse_options(arg)
  simple_arg   = arg.gsub(/(\=|_)\d+/, '')
  is_match_num = arg.match(/\d+/)
  num          = is_match_num[0].to_i if is_match_num
  simple_arg   = SUPPORT_ARGS.key(simple_arg) if SUPPORT_ARGS.values.include?(simple_arg)

  if SUPPORT_ARGS.keys.include?(simple_arg)
    { simple_arg.gsub(/-/, '') => num }
  else
    raise ParseError, "invalid option names #{arg}"
  end
end

def parse_file(arg)
  File.open(arg, 'r')
rescue
  puts "Error: could not read file #{arg}"
end

def parse_pattern(arg)
  arg.split(' ').each.map do |patten|
    begin
      raise PatternError, "Error: cannot parse regex #{patten}" unless patten.match?(/\/.*\/\d?+/)

      exp = eval(patten)
      raise PatternError, "Error: cannot parse regex #{patten}" unless exp.is_a?(Regexp)

      exp
    rescue SyntaxError, PatternError
      puts "Error: cannot parse regex #{patten}"
    end
  end.compact
end

def match_file(file, options, patterns, prefix = '')
  case mult_arg(options)
  when 'v'
    match_v(file, patterns, prefix)
  when 'c', 'co'
    match_normal(file, patterns, prefix, true)
  when 'cv'
    match_v(file, patterns, prefix, true)
  when 'l'
    match_l(file, patterns)
  when 'L'
    match_l(file, patterns, true)
  when 'o'
    match_o(file, patterns, prefix)
  when 'F'
    match_f(file, patterns, prefix)
  when 'Fc'
    match_f(file, patterns, prefix, true)
  when 'Fo'
    match_f(file, patterns, prefix, false, true)
  when 'Fv'
    match_fv(file, patterns, prefix)
  when 'Fcv'
    match_fv(file, patterns, prefix, true)
  when 'A'
    match_a(file, patterns, options['A'], prefix)
  when 'Av'
    match_av(file, patterns, options['A'], prefix)
  when 'B'
    match_b(file, patterns, options['B'], prefix)
  when 'Bv'
    match_bv(file, patterns, options['B'], prefix)
  when 'C'
    match_c(file, patterns, options['C'], prefix)
  when 'Cv'
    match_cv(file, patterns, options['C'], prefix)
  else
    match_normal(file, patterns, prefix)
  end
end

def match_normal(file, patterns, prefix, is_c = false)
  file.each_with_index do |line, index|
    puts("#{prefix}#{is_c ? index + 1 : line}") if line.match?(patterns)
  end
end

def match_v(file, patterns, prefix, is_c = false)
  file.each_with_index do |line, index|
    puts("#{prefix}#{is_c ? index + 1 : line}") unless line.match?(patterns)
  end
end

def match_f(file, patterns, prefix, is_c = false, is_o = false)
  file.each_with_index do |line, index|
    is_match = false
    content  = ''

    patterns.each do |pattern|
      if line.include?(pattern)
        is_match = true
        content  += pattern
      end
    end

    content = is_o ? content : line
    puts("#{prefix}#{is_c ? index + 1 : content}") if is_match
  end
end

def match_a(file, patterns, num, prefix)
  content     = file.to_a
  first_match = true
  content.each_with_index do |line, index|
    if line.match?(patterns)
      puts '--' unless first_match
      puts prefix + line
      puts prefix + content[index + num] if content[index + num]

      first_match = false
    end
  end
end

def match_av(file, patterns, num, prefix)
  content     = file.to_a
  first_match = true
  content.each_with_index do |line, index|
    unless line.match?(patterns)
      puts '--' unless first_match
      puts prefix + line
      puts prefix + content[index + num] if content[index + num]

      first_match = false
    end
  end
end

def match_b(file, patterns, num, prefix)
  content     = file.to_a
  first_match = true
  content.each_with_index do |line, index|
    if line.match?(patterns)
      puts '--' unless first_match
      puts prefix + line
      puts prefix + content[index - num] if index - num >= 0 && content[index - num]

      first_match = false
    end
  end
end

def match_bv(file, patterns, num, prefix)
  content     = file.to_a
  first_match = true
  content.each_with_index do |line, index|
    unless line.match?(patterns)
      puts '--' unless first_match
      puts prefix + line
      puts prefix + content[index - num] if index - num >= 0 && content[index - num]

      first_match = false
    end
  end
end

def match_c(file, patterns, num, prefix)
  content     = file.to_a
  first_match = true
  content.each_with_index do |line, index|
    if line.match?(patterns)
      puts '--' unless first_match
      puts prefix + line
      puts prefix + content[index - num] if index - num >= 0 && content[index - num]
      puts prefix + content[index + num] if content[index + num]

      first_match = false
    end
  end
end

def match_cv(file, patterns, num, prefix)
  content     = file.to_a
  first_match = true
  content.each_with_index do |line, index|
    unless line.match?(patterns)
      puts '--' unless first_match
      puts prefix + line
      puts prefix + content[index - num] if index - num >= 0 && content[index - num]
      puts prefix + content[index + num] if content[index + num]

      first_match = false
    end
  end
end

def match_fv(file, patterns, prefix, is_c = false)
  file.each_with_index do |line, index|
    is_match = false

    patterns.each do |pattern|
      if line.include?(pattern)
        is_match = true
      end
    end

    puts("#{prefix}#{is_c ? index + 1 : line}") unless is_match
  end
end

def match_l(file, patterns, is_cap_l = false)
  match_l = false

  file.each do |line|
    match_l = true if line.match?(patterns)
  end

  puts(file.path) if !is_cap_l && match_l
  puts(file.path) if is_cap_l && !match_l
end

def match_o(file, patterns, prefix)
  file.each_with_index do |line, index|
    match_exp = line.match(patterns)
    puts("#{prefix}#{match_exp[0]}") if match_exp
  end
end

# :nocov:
options, patterns, files = parseArgs(args)
return if files.nil? || files.empty?

if options.keys.include?('F')
  patterns = patterns.map(&:inspect)
else
  patterns = Regexp.union(*patterns)
end

if files.length == 1
  match_file(files.first, options, patterns)
else
  files.each do |file|
    prefix = "#{file.path}: "
    match_file(file, options, patterns, prefix)
  end
end