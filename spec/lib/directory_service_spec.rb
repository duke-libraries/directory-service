require 'spec_helper'

describe DirectoryService do
  let(:filter) { double("filter") }
  let(:results) { double("results") }
  subject { described_class.new }
  describe "#client" do
    it "should be a Net::LDAP client" do
      expect(subject.send(:client)).to be_a(Net::LDAP)
    end
  end
  describe "#search" do
    it "should raise a custom expection on an LDAP error" do
      allow(subject).to receive(:_search).with(hash_including(filter: filter, attributes: nil)).and_raise(Net::LDAP::LdapError)
      expect { subject.search(filter) }.to raise_error(DirectoryService::Error)
    end
  end
  describe "#search_one_result" do
    before do
      allow(subject).to receive(:search).with(filter, {}) { results }
    end
    it "should raise an exception when multiple results are returned" do
      allow(results).to receive(:empty?) { false }
      allow(results).to receive(:size) { 2 }
      expect { subject.search_one_result(filter) }.to raise_error(DirectoryService::MultipleResultsError)
    end
    it "should raise an exception when no results are returned" do
      allow(results).to receive(:empty?) { true }
      expect { subject.search_one_result(filter) }.to raise_error(DirectoryService::NoResultsError)
    end
  end
end

describe DirectoryService::Result do
  let(:ldap_entry) { double("ldap_entry") }
  subject { described_class.new(ldap_entry) }
  describe "key access to attributes" do
    it "should delegate to the ldap entry" do
      expect(subject.ldap_entry).to receive(:[]).with("foo")
      subject["foo"]
    end
  end
  describe "method access to attributes" do
    it "should return the attribute value if attribute present" do
      allow(ldap_entry).to receive(:attribute_names) { ["foo", "bar"] }
      allow(subject).to receive(:has_attribute?).with(:foo) { true }
      allow(subject).to receive(:[]).with("foo") { ["spam", "eggs"] }
      expect(subject.foo).to eq(["spam", "eggs"])
    end
    it "should raise an exception if the attribute not present" do
      allow(ldap_entry).to receive(:attribute_names) { ["bar"] }
      expect { subject.foo }.to raise_error(NoMethodError)
    end
  end
  describe "#first_value" do
    it "should return the first value of attribute if present" do
      allow(subject).to receive(:[]).with("foo") { ["spam", "eggs"] }
      expect(subject.first_value("foo")).to eq("spam")
    end
    it "should return nil if attribute not present" do
      allow(subject).to receive(:[]).with("foo") { nil }
      expect(subject.first_value("foo")).to be_nil
    end
  end
end
