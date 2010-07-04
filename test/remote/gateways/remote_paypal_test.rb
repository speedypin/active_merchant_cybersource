require 'test_helper'

class PaypalTest < Test::Unit::TestCase
  def setup
    Base.gateway_mode = :test
    
    @gateway = PaypalGateway.new(fixtures(:paypal_certificate))

    @creditcard = CreditCard.new(
      :type                => "visa",
      :number              => "4381258770269608", # Use a generated CC from the paypal Sandbox
      :verification_value => "000",
      :month               => 1,
      :year                => Time.now.year + 1,
      :first_name          => 'Fred',
      :last_name           => 'Brooks'
    )
       
    @params = {
      :order_id => generate_unique_id,
      :email => 'buyer@jadedpallet.com',
      :billing_address => { :name => 'Fred Brooks',
                    :address1 => '1234 Penny Lane',
                    :city => 'Jonsetown',
                    :state => 'NC',
                    :country => 'US',
                    :zip => '23456'
                  } ,
      :description => 'Stuff that you purchased, yo!',
      :ip => '10.0.0.1'
    }
      
    @recurring_params = {
      # :name => # if not spec'd, the name on card will be used
      # :profile_id => 'I-SEVK234C8U1M', # triggers :modify on recurring
      :email => 'joe.customer@vuzit.com',
      :starting_at => Time.now + 1.month,
      :periodicity => :monthly,
      :comment => 'CHANGEME',
      :billing_address => address,
      :payments => 0,
      :initial_payment => 500
    }
    
    @amount = 100
    # test re-authorization, auth-id must be more than 3 days old.
    # each auth-id can only be reauthorized and tested once.
    # leave it commented if you don't want to test reauthorization.
    # 
    #@three_days_old_auth_id  = "9J780651TU4465545" 
    #@three_days_old_auth_id2 = "62503445A3738160X" 
  end

  # def test_successful_purchase
  #   response = @gateway.purchase(@amount, @creditcard, @params)
  #   assert_success response
  #   assert response.params['transaction_id']
  # end
  # 
  # def test_successful_purchase_with_api_signature
  #   gateway = PaypalGateway.new(fixtures(:paypal_signature))
  #   response = gateway.purchase(@amount, @creditcard, @params)
  #   assert_success response
  #   assert response.params['transaction_id']
  # end
  # 
  # def test_failed_purchase
  #   @creditcard.number = '234234234234'
  #   response = @gateway.purchase(@amount, @creditcard, @params)
  #   assert_failure response
  #   assert_nil response.params['transaction_id']
  # end
  # 
  # def test_successful_authorization
  #   response = @gateway.authorize(@amount, @creditcard, @params)
  #   assert_success response
  #   assert response.params['transaction_id']
  #   assert_equal '1.00', response.params['amount']
  #   assert_equal 'USD', response.params['amount_currency_id']
  # end
  # 
  # def test_failed_authorization
  #   @creditcard.number = '234234234234'
  #   response = @gateway.authorize(@amount, @creditcard, @params)
  #   assert_failure response
  #   assert_nil response.params['transaction_id']
  # end
  # 
  # def test_successful_reauthorization
  #   return if not @three_days_old_auth_id
  #   auth = @gateway.reauthorize(1000, @three_days_old_auth_id)
  #   assert_success auth
  #   assert auth.authorization
  #   
  #   response = @gateway.capture(1000, auth.authorization)
  #   assert_success response
  #   assert response.params['transaction_id']
  #   assert_equal '10.00', response.params['gross_amount']
  #   assert_equal 'USD', response.params['gross_amount_currency_id']
  # end
  # 
  # def test_failed_reauthorization
  #   return if not @three_days_old_auth_id2  # was authed for $10, attempt $20
  #   auth = @gateway.reauthorize(2000, @three_days_old_auth_id2)
  #   assert_false auth?
  #   assert !auth.authorization
  # end
  #     
  # def test_successful_capture
  #   auth = @gateway.authorize(@amount, @creditcard, @params)
  #   assert_success auth
  #   response = @gateway.capture(@amount, auth.authorization)
  #   assert_success response
  #   assert response.params['transaction_id']
  #   assert_equal '1.00', response.params['gross_amount']
  #   assert_equal 'USD', response.params['gross_amount_currency_id']
  # end
  # 
  # # NOTE THIS SETTING: http://skitch.com/jimmybaker/nysus/payment-receiving-preferences-paypal
  # # PayPal doesn't return the InvoiceID in the response, so I am unable to check for it. Looking at the transaction
  # # on PayPal's site will show "NEWID123" as the InvoiceID.
  # def test_successful_capture_updating_the_invoice_id
  #   auth = @gateway.authorize(@amount, @creditcard, @params)
  #   assert_success auth
  #   response = @gateway.capture(@amount, auth.authorization, :order_id => "NEWID123")
  #   assert_success response
  #   assert response.params['transaction_id']
  #   assert_equal '1.00', response.params['gross_amount']
  #   assert_equal 'USD', response.params['gross_amount_currency_id']
  # end
  # 
  # def test_successful_voiding
  #   auth = @gateway.authorize(@amount, @creditcard, @params)
  #   assert_success auth
  #   response = @gateway.void(auth.authorization)
  #   assert_success response
  # end
  # 
  # def test_purchase_and_full_credit
  #   purchase = @gateway.purchase(@amount, @creditcard, @params)
  #   assert_success purchase
  #   
  #   credit = @gateway.credit(@amount, purchase.authorization, :note => 'Sorry')
  #   assert_success credit
  #   assert credit.test?
  #   assert_equal 'USD',  credit.params['net_refund_amount_currency_id']
  #   assert_equal '0.67', credit.params['net_refund_amount']
  #   assert_equal 'USD',  credit.params['gross_refund_amount_currency_id']
  #   assert_equal '1.00', credit.params['gross_refund_amount']
  #   assert_equal 'USD',  credit.params['fee_refund_amount_currency_id']
  #   assert_equal '0.33', credit.params['fee_refund_amount']
  # end
  # 
  # def test_failed_voiding
  #   response = @gateway.void('foo')
  #   assert_failure response
  # end
  # 
  # def test_successful_transfer
  #   response = @gateway.purchase(@amount, @creditcard, @params)
  #   assert_success response
  #   
  #   response = @gateway.transfer(@amount, 'joe@example.com', :subject => 'Your money', :note => 'Thanks for taking care of that')
  #   assert_success response
  # end
  # 
  # def test_failed_transfer
  #    # paypal allows a max transfer of $10,000
  #   response = @gateway.transfer(1000001, 'joe@example.com')
  #   assert_failure response
  # end
  # 
  # def test_successful_multiple_transfer
  #   response = @gateway.purchase(900, @creditcard, @params)
  #   assert_success response
  #   
  #   response = @gateway.transfer([@amount, 'joe@example.com'],
  #     [600, 'jane@example.com', {:note => 'Thanks for taking care of that'}],
  #     :subject => 'Your money')
  #   assert_success response
  # end
  # 
  # def test_failed_multiple_transfer
  #   response = @gateway.purchase(25100, @creditcard, @params)
  #   assert_success response
  # 
  #   # You can only include up to 250 recipients
  #   recipients = (1..251).collect {|i| [100, "person#{i}@example.com"]}
  #   response = @gateway.transfer(*recipients)
  #   assert_failure response
  # end
  # 
  # # Makes a purchase then makes another purchase adding $1.00 using just a reference id (transaction id)
  # def test_successful_referenced_id_purchase
  #   response = @gateway.purchase(@amount, @creditcard, @params)
  #   assert_success response
  #   id_for_reference = response.params['transaction_id']
  #   
  #   @params.delete(:order_id)
  #   response2 = @gateway.purchase(@amount + 100, id_for_reference, @params)
  #   assert_success response2
  # end

  def test_create_recurring_profile
    response = @gateway.recurring(1000, @creditcard, @recurring_params)
    assert_success response
    assert !response.params['profile_id'].blank?
    assert response.test?
  end
  
  def test_create_recurring_profile_with_invalid_date
    response = @gateway.recurring(1000, @creditcard, @recurring_params.merge(:starting_at => Time.now))
    assert_failure response
    assert_equal 'Field format error: Start or next payment date must be a valid future date', response.message
    assert response.params['profile_id'].blank?
    assert response.test?
  end
  
  def test_create_and_cancel_recurring_profile
    response = @gateway.recurring(1000, @creditcard, @recurring_params)
    assert_success response
    assert !response.params['profile_id'].blank?
    assert response.test?
    
    response = @gateway.cancel_recurring(response.params['profile_id'])
    assert_success response
    assert response.test?
  end
  
  def test_full_feature_set_for_recurring_profiles
    # Test add
    @recurring_params.merge(
      :periodicity => :weekly,
      :payments => '12',
      :starting_at => Time.now + 1.day,
      :comment => "Test Profile"
    )
    response = @gateway.recurring(100, @creditcard, @recurring_params)
    assert_equal "Approved", response.params['message']
    assert_equal "0", response.params['result']
    assert_success response
    assert response.test?
    assert !response.params['profile_id'].blank?
    @recurring_profile_id = response.params['profile_id']
  
    # Test modify
    @recurring_params.merge(
      :periodicity => :monthly,
      :starting_at => Time.now + 1.day,
      :payments => '4',
      :profile_id => @recurring_profile_id
    )
    response = @gateway.recurring(400, @credit_card, @recurring_params)
    assert_equal "Approved", response.params['message']
    assert_equal "0", response.params['result']
    assert_success response
    assert response.test?
    
    # Test inquiry
    response = @gateway.recurring_inquiry(@recurring_profile_id) 
    assert_equal "0", response.params['result']
    assert_success response
    assert response.test?
    
    # Test payment history inquiry
    response = @gateway.recurring_inquiry(@recurring_profile_id, :history => true)
    assert_equal '0', response.params['result']
    assert_success response
    assert response.test?
    
    # Test cancel
    response = @gateway.cancel_recurring(@recurring_profile_id)
    assert_equal "Approved", response.params['message']
    assert_equal "0", response.params['result']
    assert_success response
    assert response.test?
  end
  
  def test_recurring_with_initial_authorization
    @recurring_params.merge(
      :initial_transaction => {
        :type => :authorization
      }
    )
    response = @gateway.recurring(1000, @creditcard, @recurring_params)
    assert_success response
    assert !response.params['profile_id'].blank?
    assert response.test?
  end
  
  def test_recurring_with_initial_authorization
    @recurring_params.merge(
      :initial_transaction => {
        :type => :purchase,
        :amount => 500
      }
    )
    response = @gateway.recurring(1000, @creditcard, @recurring_params)
    assert_success response
    assert !response.params['profile_id'].blank?
    assert response.test?
  end

end
