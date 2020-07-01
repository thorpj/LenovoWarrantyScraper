require './test/test_helper'

class LenovoWarrantyScraperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LenovoWarrantyScraper::VERSION
  end

  def test_temp
    # LenovoWarrantyScraper.single_claim(LenovoWarrantyScraper.load_secrets, LenovoWarrantyScraper.load_settings, 'R90T9B08', 'Churchlands SHS', 'S15/04/20 10:10 AM', '02HM004', 'Wont turn on', 'Disconnected battery, reseated ram. tested spare ram. tested spare motherboard working' )
    LenovoWarrantyScraper.single_claim(settings: LenovoWarrantyScraper.load_settings, secrets:  LenovoWarrantyScraper.load_secrets, serial_number: 'R90WLG2Y', customer: 'Churchlands SHS', ticket_number: 'T20200624.0020', parts: ['02DL831'], failure_description: 'Doesnt turn on', comments: 'Tried spare charger, same issue, tried spare ram, same issue, tried spare board - working', service_type: 'DOA', doa_warranty_reference: '7039113780')

  end

end
