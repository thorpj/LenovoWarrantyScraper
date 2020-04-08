require './test/test_helper'

class LenovoWarrantyScraperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LenovoWarrantyScraper::VERSION
  end


end
