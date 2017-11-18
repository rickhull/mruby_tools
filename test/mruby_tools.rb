require 'mruby_tools'
require 'minitest/autorun'

describe MRubyTools do
  describe "c_wrapper" do
    it "must return a string of mruby C code" do
      [[], [__FILE__]].each { |rb_files|
        str = MRubyTools.c_wrapper(rb_files)
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

  describe "rb2c" do
    it "must inject the contents of a ruby file into mrb_load_string()" do
      str = MRubyTools.rb2c(__FILE__)
      str.must_be_kind_of String
      str.wont_be_empty
      str.must_match(/mrb_load_n?string\(/)
      str.must_match(/exc/)
    end
  end

  describe "new instance" do
    if File.directory? MRubyTools::MRUBY_DIR
      it "must instantiate properly with MRUBY_DIR" do
        t = MRubyTools.new
        t.must_be_kind_of MRubyTools
        i = t.mruby_inc
        i.must_be_kind_of String
        i.must_match %r{include}
        File.directory?(i).must_equal true
        a = t.mruby_ar
        a.must_be_kind_of String
        a.must_match %r{libmruby.a}
        File.readable?(a).must_equal true
      end
    else
      it "must raise without a valid MRUBY_DIR" do
        proc { MRubyTools.new }.must_raise MRubyTools::MRubyNotFound
      end
    end
  end

  describe MRubyTools::CLI do
    describe "args" do
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
end
