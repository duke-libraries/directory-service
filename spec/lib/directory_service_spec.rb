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
    it "should raise a custom exception on an LDAP error" do
      allow(subject).to receive(:_search).with(hash_including(filter: filter, attributes: nil)).and_raise(Net::LDAP::LdapError)
      expect { subject.search(filter) }.to raise_error(DirectoryService::Error)
    end
  end
  describe "#find_by_*" do
    it "should call `search' and return the first result" do
      allow(subject).to receive(:search).with(Net::LDAP::Filter.eq("uid", "bob"), {}) { ["Bob Smith"] }
      expect(subject.find_by_uid("bob")).to eq("Bob Smith")
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
