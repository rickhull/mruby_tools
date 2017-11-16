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

  describe "mruby_src_dir" do
    it "must confirm the specified mruby source on the filesystem" do
      candidates = []
      %w{src git}.each { |subdir|
        candidates +=
          Dir[File.join(ENV['HOME'], subdir, 'mruby-1.*', 'include')]
      }
      unless candidates.empty?
        latest = File.expand_path('..', candidates.last)
        key = 'TESTING_MRUBY_SRC_DIR'
        ENV[key] = latest
        dir = MRubyTools.mruby_src_dir(key)
        File.directory?(dir).must_equal true
        File.directory?(File.join(dir, 'include')).must_equal true
      end
    end

    it "must accept the dir specification from the environment" do
      proc { MRubyTools.mruby_src_dir('bad key') }.must_raise Exception
    end
  end

  describe "args" do
    it "must provide a hash with expected keys" do
      h = MRubyTools.args([])
      h.must_be_kind_of Hash
      [:verbose, :help, :c_file, :out_file, :rb_files].each { |key|
        h.key?(key).must_equal true
      }
      h[:verbose].must_equal false
      h[:help].must_equal false
      [Tempfile, File].must_include h[:c_file].class
      h[:out_file].must_be_kind_of String
      h[:out_file].wont_be_empty
      h[:rb_files].must_be_kind_of Array
      h[:rb_files].must_be_empty
    end
  end
end
