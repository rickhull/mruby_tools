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
      proc { @invalid.validate! }.must_raise MRubyTools::MRubyNotFound
    end

    it "must have ivars" do
      [@valid, @invalid].each { |obj|
        obj.mruby_dir.must_be_kind_of String
        obj.inc_path.must_be_kind_of String
        obj.ar_path.must_be_kind_of String
      }
      @valid.inc_path.must_match %r{include}
      @valid.ar_path.must_match %r{libmruby.a}
    end
  end

  describe "C.slurp_rb" do
    it "must inject the contents of a ruby file into mrb_load_string()" do
      str = MRubyTools::C.slurp_rb(__FILE__)
      str.must_be_kind_of String
      str.wont_be_empty
      str.must_match(/mrb_load_n?string\(/)
      str.must_match(/exc/)
    end
  end

  describe "C.wrapper" do
    it "must return a string of mruby C code" do
      [[], [__FILE__]].each { |rb_files|
        str = MRubyTools::C.wrapper(rb_files)
        str.must_be_kind_of String
        str.wont_be_empty
        str.must_match(/main\(void\)/)
        str.must_match(/return/)
        str.must_match(/exit/)
        str.must_match(/mruby/)
        str.must_match(/mrb/)
      }
    end
  end

  describe "CLI.args" do
    it "must provide a hash with expected keys" do
      h = MRubyTools::CLI.args([])
      h.must_be_kind_of Hash
      [:verbose, :help, :c_file,
       :out_file, :rb_files, :mruby_dir].each { |key|
        h.key?(key).must_equal true
      }
      h[:verbose].must_equal false
      h[:help].must_equal false
      [Tempfile, File].must_include h[:c_file].class
      h[:out_file].must_be_kind_of String
      h[:out_file].wont_be_empty
      h[:rb_files].must_be_kind_of Array
      h[:rb_files].must_be_empty
      h[:mruby_dir].must_be_nil
    end
  end
end
