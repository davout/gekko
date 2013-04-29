require_relative '../spec_helper'

describe 'Account' do

  describe 'get_ledger' do
    let(:ledger) do
      VCR.use_cassette('ledger', match_requests_on: [:method, :anonymized_uri]) do
        Paytunia.get_ledger
      end
    end

    it 'must return the ledger' do
      ledger.should be_an_instance_of Array
      ledger.last.balance.should be_an_instance_of BigDecimal
    end
  end


  describe 'get_operation' do
    let(:account_operation) do
      VCR.use_cassette('account_operation', match_requests_on: [:method, :anonymized_uri]) do
        Paytunia.get_operation('c503b258-2ad8-49a5-a8c6-b3ecad05ba70')
      end
    end

    it 'must be an instance of AccountOperation' do
      account_operation.should be_an_instance_of Paytunia::Api::AccountOperation
    end
  end
end