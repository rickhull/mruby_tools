require 'mruby_tools'
require 'minitest/autorun'

describe MRubyTools do
  describe "new instance" do
    before do
      @valid = MRubyTools.new
      @invalid = MRubyTools.new('blah blah')
    end

    it "must validate!" do
      @valid.validate! if @valid.built?
      expect { @invalid.validate! }.must_raise MRubyTools::MRubyNotFound
    end

    it "must have ivars" do
      [@valid, @invalid].each { |obj|
        expect(obj.mruby_dir).must_be_kind_of String
        expect(obj.inc_path).must_be_kind_of String
        expect(obj.ar_path).must_be_kind_of String
        expect(obj.bin_path).must_be_kind_of String
      }
      expect(@valid.inc_path).must_match %r{include}
      expect(@valid.ar_path).must_match %r{libmruby.a}
      expect(@valid.bin_path).must_match %r{bin}
    end
  end

  describe "C.slurp_rb" do
    it "must inject the contents of a ruby file into mrb_load_string()" do
      str = MRubyTools::C.slurp_rb(__FILE__)
      expect(str).must_be_kind_of String
      expect(str).wont_be_empty
      expect(str).must_match %r{mrb_load_n?string\(}
      expect(str).must_match %r{exc}
    end
  end

  describe "C.slurp_mrb" do
    it "must inject the contents of a bytecode file into test_symbol[]" do
      # bytecode is pure binary -- it doesn't matter what file we provide
      str = MRubyTools::C.slurp_mrb(__FILE__)
      expect(str).must_be_kind_of String
      expect(str).wont_be_empty
      expect(str).must_match %r{test_symbol}
      expect(str).must_match %r{0x\d\d,}
    end
  end

  describe "C.wrapper" do
    it "must return a string of mruby C code" do
      [[], [__FILE__]].each { |rb_files|
        str = MRubyTools::C.wrapper(rb_files)
        expect(str).must_be_kind_of String
        expect(str).wont_be_empty
        expect(str).must_match %r{main\(void\)}
        expect(str).must_match %r{return}
        expect(str).must_match %r{exit}
        expect(str).must_match %r{mruby}
        expect(str).must_match %r{mrb}
      }
    end
  end

  describe "C.bytecode_wrapper" do
    it "must return a string of mruby C code" do
      str = MRubyTools::C.bytecode_wrapper(__FILE__)
      expect(str).must_be_kind_of String
      expect(str).wont_be_empty
      expect(str).must_match %r{main\(void\)}
      expect(str).must_match %r{return}
      expect(str).must_match %r{exit}
      expect(str).must_match %r{mruby}
      expect(str).must_match %r{mrb}
    end
  end

  describe "CLI.args" do
    it "must provide a hash with expected keys" do
      h = MRubyTools::CLI.args([])
      expect(h).must_be_kind_of Hash
      [:verbose, :help, :c_file,
       :out_file, :rb_files, :mruby_dir].each { |key|
        expect(h.key?(key)).must_equal true
      }
      expect(h[:verbose]).must_equal false
      expect(h[:help]).must_equal false
      expect([Tempfile, File]).must_include h[:c_file].class
      expect(h[:out_file]).must_be_kind_of String
      expect(h[:out_file]).wont_be_empty
      expect(h[:rb_files]).must_be_kind_of Array
      expect(h[:rb_files]).must_be_empty
      expect(h[:mruby_dir]).must_be_nil
    end
  end
end
