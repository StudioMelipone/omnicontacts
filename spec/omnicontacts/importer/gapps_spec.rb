require "spec_helper"
require "omnicontacts/importer/gapps"

describe OmniContacts::Importer::Gapps do

  let(:gapps) { OmniContacts::Importer::Gapps.new({}, "client_id", "client_secret") }

  let(:contacts_as_xml) {
    "<entry xmlns:gd='http://schemas.google.com/g/2005'>
       <gd:name>
         <gd:fullName>Edward Bennet</gd:fullName>
       </gd:name>
       <gd:email rel='http://schemas.google.com/g/2005#work' primary='true' address='bennet@gmail.com'/>
     </entry>"
  }

  let(:contact_without_fullname) {
    "<entry xmlns:gd='http://schemas.google.com/g/2005'>
       <gd:name/>
       <gd:email rel='http://schemas.google.com/g/2005#work' primary='true' address='bennet@gmail.com'/>
     </entry>"
  }

  let(:user_infos_as_json) {
    "{\"email\":\"team@card.biz\",\"verified_email\":true,\"hd\":\"card.biz\"}"
  }

  describe "fetch_profiles" do

    let(:token) { "token" }
    let(:token_type) { "token_type" }
    let(:domain) { "test.com" }

    it "should request the contacts by specifying version and code in the http headers" do
      gapps.should_receive(:https_get) do |host, path, params, headers|
        headers["GData-Version"].should eq("3.0")
        headers["Authorization"].should eq("#{token_type} #{token}")
        contacts_as_xml
      end
      gapps.fetch_profiles token, token_type, domain
    end

    it "should correctly parse name and email" do
      gapps.should_receive(:https_get).and_return(contacts_as_xml)
      result = gapps.fetch_profiles token, token_type, domain
      result.size.should be(1)
      result.first[:name].should eq("Edward Bennet")
      result.first[:email].should eq("bennet@gmail.com")
    end

    it "should handle contact without fullname" do
      gapps.should_receive(:https_get).and_return(contact_without_fullname)
      result = gapps.fetch_profiles token, token_type, domain
      result.size.should be(1)
      result.first[:name].should be_nil
      result.first[:email].should eq("bennet@gmail.com")
    end
  end

  describe "fetch_domain" do
    let(:token) { "token" }
    let(:token_type) { "token_type" }

    it "should request the user infos by specifying version and code in the http headers" do
      gapps.should_receive(:https_get) do |host, path, params, headers|
        headers["GData-Version"].should eq("3.0")
        headers["Authorization"].should eq("#{token_type} #{token}")
        user_infos_as_json
      end
      gapps.fetch_domain token, token_type
    end


    it "should correctly parse domain" do
      gapps.should_receive(:https_get).and_return(user_infos_as_json)
      result = gapps.fetch_domain token, token_type
      result.should eq("card.biz")
    end

  end

end
