#  gem install simplecov for coverage
# uncomment the following two lines to generate coverage report
require 'simplecov'
SimpleCov.start
require_relative File.join("..", "src", "rugrep")

# write rspec tests
context '#parse_options' do
  it 'parse simple options' do
    expect(parse_options('-v')).to eq({ 'v' => nil })
    expect(parse_options('--invert-match')).to eq({ 'v' => nil })
    expect(parse_options('-L')).to eq({ 'L' => nil })
    expect(parse_options('--files-without-match')).to eq({ 'L' => nil })
  end

  it 'parse option with num' do
    expect(parse_options('-A_123')).to eq({ 'A' => 123 })
    expect(parse_options('--after-context=123')).to eq({ 'A' => 123 })
  end

  it 'invalid options' do
    expect { parse_options('-a') }.to raise_error ParseError
    expect { parse_options('-A_D') }.to raise_error ParseError
  end
end

context '#parse_file' do
  it 'parse a right file' do
    expect(parse_file('./tests/rugrep_spec.rb')).to be_a File
    expect(parse_file('./tests/rugrep_spec.rb').path).to eq('./tests/rugrep_spec.rb')
  end

  it 'parse a not exists file' do
    expect(parse_file('./tests/rugrep_spec.rbs')).to be_nil
  end
end

context '#parse_pattern' do
  it 'parse a right patten' do
    expect(parse_pattern('/a/ /b/')).to eq([/a/, /b/])
    expect(parse_pattern('/a/')).to eq([/a/])
  end

  it 'parse a error pattern' do
    expect(parse_pattern('/a/ /b')).to eq([/a/])

    expect do
      parse_pattern('/a/ /b')
    end.to output("Error: cannot parse regex /b\n").to_stdout
  end
end

context '#parseArgs' do
  it 'success' do
    options, patterns, files = parseArgs(['-v', '-c', '/a/ /b/', 'tests/rugrep_spec.rb'])

    expect(options).to eq({ 'c' => nil, 'v' => nil })
    expect(patterns).to eq([/a/, /b/])
    expect(files.first.path).to eq('tests/rugrep_spec.rb')
  end

  it 'less than 2 arguments.' do
    expect do
      parseArgs(['l'])
    end.to output("less than 2 arguments.\n").to_stdout
  end

  it 'patterns are not contiguously placed.' do
    expect do
      parseArgs(['/a/', '/a/'])
    end.to output("patterns are not contiguously placed.\n").to_stdout
  end

  it 'not support' do
    expect do
      parseArgs(['aaaa', 'bbbb'])
    end.to output("not support arg aaaa\n").to_stdout
  end

  it 'no patterns are provided as arguments.' do
    expect do
      parseArgs(['-v', '-c'])
    end.to output("no patterns are provided as arguments.\n").to_stdout
  end

  it 'invalid option combinations.' do
    expect do
      parseArgs(['-l', '-c', '/a/ /b/'])
    end.to output("invalid option combinations.\n").to_stdout
  end
end

context '#match_file' do
  before do
    @file   = File.open('tests/test_match.txt')
    @file2  = File.open('tests/test_match_2.txt')
    @file_a = File.open('tests/test_match_A.txt')
    @file_f = File.open('tests/test_match_F.txt')
    @file_o = File.open('tests/test_match_o.txt')
  end

  it 'match_normal' do
    expect do
      match_file(@file, {}, /a/)
    end.to output("a\n").to_stdout
  end

  it 'match_v' do
    expect do
      match_file(@file, { 'v' => nil }, /a/)
    end.to output("b\nc\nd\n").to_stdout
  end
  it 'match_c' do
    expect do
      match_file(@file, { 'c' => nil }, /a/)
    end.to output("1\n").to_stdout
  end

  it 'match_cv' do
    expect do
      match_file(@file, { 'c' => nil, 'v' => nil }, /a/)
    end.to output("2\n3\n4\n").to_stdout
  end
  it 'match_l' do
    expect do
      match_file(@file, { 'l' => nil }, /a/)
    end.to output("tests/test_match.txt\n").to_stdout
  end
  it 'match_L' do
    expect do
      match_file(@file, { 'L' => nil }, /aAAA/)
    end.to output("tests/test_match.txt\n").to_stdout
  end
  it 'match_o' do
    expect do
      match_file(@file_o, { 'o' => nil }, /bs/)
    end.to output("bs\n").to_stdout
  end

  it 'match_oc' do
    expect do
      match_file(@file_o, { 'o' => nil, 'c' => nil }, /bs/)
    end.to output("2\n").to_stdout
  end

  it 'match_f' do
    expect do
      match_file(@file_f, { 'F' => nil }, ['/b/'])
    end.to output("/b/sd\n").to_stdout
  end

  it 'match_fc' do
    expect do
      match_file(@file_f, { 'F' => nil, 'c' => nil }, ['/b/'])
    end.to output("2\n").to_stdout
  end

  it 'match_fc' do
    expect do
      match_file(@file_f, { 'F' => nil, 'o' => nil }, ['/b/'])
    end.to output("/b/\n").to_stdout
  end
  it 'match_fv' do
    expect do
      match_file(@file_f, { 'F' => nil, 'v' => nil }, ['/b/'])
    end.to output("a\nc\nd\n").to_stdout
  end
  it 'match_fcv' do
    expect do
      match_file(@file_f, { 'F' => nil, 'v' => nil, 'c' => nil }, ['/b/'])
    end.to output("1\n3\n4\n").to_stdout
  end

  it 'match_A' do
    expect do
      match_file(@file_a, { 'A' => 1 }, /b/)
    end.to output("b\nc\n--\nb\nc\n").to_stdout
  end
  it 'match_Av' do
    expect do
      match_file(@file_a, { 'A' => 1, 'v' => nil }, /b/)
    end.to output("a\nb\n--\nc\nd\n--\nd\na\n--\na\nb\n--\nc\nd\n--\nd\n").to_stdout
  end

  it 'match_B' do
    expect do
      match_file(@file_a, { 'B' => 1 }, /b/)
    end.to output("b\na\n--\nb\na\n").to_stdout
  end
  it 'match_Bv' do
    expect do
      match_file(@file_a, { 'B' => 1, 'v' => nil }, /b/)
    end.to output("a\n--\nc\nb\n--\nd\nc\n--\na\nd\n--\nc\nb\n--\nd\nc\n").to_stdout
  end

  it 'match_C' do
    expect do
      match_file(@file_a, { 'C' => 1 }, /b/)
    end.to output("b\na\nc\n--\nb\na\nc\n").to_stdout
  end
  it 'match_Cv' do
    expect do
      match_file(@file_a, { 'C' => 1, 'v' => nil }, /b/)
    end.to output("a\nb\n--\nc\nb\nd\n--\nd\nc\na\n--\na\nd\nb\n--\nc\nb\nd\n--\nd\nc\n").to_stdout
  end
end

context 'run command line' do
  it 'match_normal' do
    output = `ruby src/rugrep.rb tests/test_match.txt /a/`
    expect(output).to eq("a\n")

    output = `ruby src/rugrep.rb tests/test_match.txt "/a/ /b/"`
    expect(output).to eq("a\nb\n")

    output = `ruby src/rugrep.rb tests/test_match.txt "/a/ /cd/"`
    expect(output).to eq("a\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt /a/`
    expect(output).to eq("tests/test_match.txt: a\ntests/test_match_2.txt: a\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt "/a/ /b/"`
    expect(output).to eq("tests/test_match.txt: a\ntests/test_match.txt: b\ntests/test_match_2.txt: a\ntests/test_match_2.txt: b\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt "/a/ /cd/"`
    expect(output).to eq("tests/test_match.txt: a\ntests/test_match_2.txt: a\n")
  end

  it '-v' do
    output = `ruby src/rugrep.rb tests/test_match.txt /a/ -v`
    expect(output).to eq("b\nc\nd\n")

    output = `ruby src/rugrep.rb tests/test_match.txt /a/ --invert-match`
    expect(output).to eq("b\nc\nd\n")

    output = `ruby src/rugrep.rb tests/test_match.txt "/a/ /b/" -v`
    expect(output).to eq("c\nd\n")

    output = `ruby src/rugrep.rb tests/test_match.txt "/a/ /cd/" -v`
    expect(output).to eq("b\nc\nd\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt /a/ -v`
    expect(output).to eq("tests/test_match.txt: b\ntests/test_match.txt: c\ntests/test_match.txt: d\ntests/test_match_2.txt: b\ntests/test_match_2.txt: c\ntests/test_match_2.txt: d\n")
  end

  it '-c' do
    output = `ruby src/rugrep.rb tests/test_match.txt /a/ -c`
    expect(output).to eq("1\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt /a/ -c`
    expect(output).to eq("tests/test_match.txt: 1\ntests/test_match_2.txt: 1\n")
  end

  it '-cv' do
    output = `ruby src/rugrep.rb tests/test_match.txt /a/ -c -v`
    expect(output).to eq("2\n3\n4\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt /a/ -c -v`
    expect(output).to eq("tests/test_match.txt: 2\ntests/test_match.txt: 3\ntests/test_match.txt: 4\ntests/test_match_2.txt: 2\ntests/test_match_2.txt: 3\ntests/test_match_2.txt: 4\n")
  end

  it '-l' do
    output = `ruby src/rugrep.rb tests/test_match.txt /a/ -l`
    expect(output).to eq("tests/test_match.txt\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_2.txt /a/ -l`
    expect(output).to eq("tests/test_match.txt\ntests/test_match_2.txt\n")
  end

  it '-o' do
    output = `ruby src/rugrep.rb tests/test_match_o.txt /bs/ -o`
    expect(output).to eq("bs\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_o.txt /bs/ -o`
    expect(output).to eq("tests/test_match_o.txt: bs\n")
  end

  it '-oc' do
    output = `ruby src/rugrep.rb tests/test_match_o.txt /bs/ -o -c`
    expect(output).to eq("2\n")

    output = `ruby src/rugrep.rb tests/test_match.txt tests/test_match_o.txt /bs/ -o -c`
    expect(output).to eq("tests/test_match_o.txt: 2\n")
  end

  it '-F' do
    output = `ruby src/rugrep.rb tests/test_match_F.txt /b/ -F`
    expect(output).to eq("/b/sd\n")
  end

  it 'Fc' do
    output = `ruby src/rugrep.rb tests/test_match_F.txt /b/ -F -c`
    expect(output).to eq("2\n")
  end

  it 'Fo' do
    output = `ruby src/rugrep.rb tests/test_match_F.txt /b/ -F -o`
    expect(output).to eq("/b/\n")
  end

  it 'Fv' do
    output = `ruby src/rugrep.rb tests/test_match_F.txt /b/ -F -v`
    expect(output).to eq("a\nc\nd\n")
  end

  it 'Fcv' do
    output = `ruby src/rugrep.rb tests/test_match_F.txt /b/ -F -v -c`
    expect(output).to eq("1\n3\n4\n")
  end

  it 'A_1' do
    output = `ruby src/rugrep.rb tests/test_match_A.txt /b/ -A_1`
    expect(output).to eq("b\nc\n--\nb\nc\n")
  end

  it 'Av_1' do
    output = `ruby src/rugrep.rb tests/test_match_A.txt /b/ -A_1 -v`
    expect(output).to eq("a\nb\n--\nc\nd\n--\nd\na\n--\na\nb\n--\nc\nd\n--\nd\n")
  end

  it 'B_1' do
    output = `ruby src/rugrep.rb tests/test_match_A.txt /b/ -B_1`
    expect(output).to eq("b\na\n--\nb\na\n")
  end

  it 'Bv_1' do
    output = `ruby src/rugrep.rb tests/test_match_A.txt /b/ -B_1 -v`
    expect(output).to eq("a\n--\nc\nb\n--\nd\nc\n--\na\nd\n--\nc\nb\n--\nd\nc\n")
  end

  it 'C_1' do
    output = `ruby src/rugrep.rb tests/test_match_A.txt /b/ -C_1`
    expect(output).to eq("b\na\nc\n--\nb\na\nc\n")
  end

  it 'Cv_1' do
    output = `ruby src/rugrep.rb tests/test_match_A.txt /b/ -C_1 -v`
    expect(output).to eq("a\nb\n--\nc\nb\nd\n--\nd\nc\na\n--\na\nd\nb\n--\nc\nb\nd\n--\nd\nc\n")
  end
end
