require './test/test_helper'

class LenovoWarrantyScraperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LenovoWarrantyScraper::VERSION
  end

  def test_it_does_something_useful
    assert false
  end

  def test_i
    LenovoWarrantyScraper.single_claim(LenovoWarrantyScraper.load_secrets, LenovoWarrantyScraper.load_settings, 'R90T4Z94', 'Churchlands', 'T2020', '01FR030', 'Device not charging', 'Updated BIOS, Tested charger with spare device - not working, tested spare charger with customer device working')
  end

end
