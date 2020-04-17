require './test/test_helper'

class LenovoWarrantyScraperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LenovoWarrantyScraper::VERSION
  end

  def test_temp
    # LenovoWarrantyScraper.single_claim(LenovoWarrantyScraper.load_secrets, LenovoWarrantyScraper.load_settings, 'R90T9B08', 'Churchlands SHS', 'S15/04/20 10:10 AM', '02HM004', 'Wont turn on', 'Disconnected battery, reseated ram. tested spare ram. tested spare motherboard working' )
    LenovoWarrantyScraper.single_claim(LenovoWarrantyScraper.load_secrets, LenovoWarrantyScraper.load_settings, 'R90SFGM6', 'Churchlands SHS', 'S15/04/20 10:10 AM', '01YP240', 'Keys on keyboard not working', 'Reseated keyboard, updated bios, reimaged device, tested spare keyboard working' )

  end

end
