require 'openssl'
require 'base64'

# Copyright (C) 2010-2017 Íbúar ses / Citizens Foundation Iceland
# Authors Robert Bjarnason, Gunnar Grimsson & Guðny Maren Valsdottir
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class BudgetVoteHelper
  NEW_PRIORITIES_ARRAY_ID = 0

  attr_reader :item_ids, :vote

  @@private_key_file_data = nil
  @@private_key = nil

  def initialize(encrypted_payload, private_key_file, passphrase, vote)
    @encrypted_payload = encrypted_payload
    @@private_key_file_data = File.read(private_key_file)
    @@private_key = OpenSSL::PKey::RSA.new(@@private_key_file_data, passphrase)
    @vote = vote
  end

  def unencryped_vote_for_audit_csv
    # Decrypt the vote for the audit csv
    unpack
  end

  def pack(public_key_file,item_ids)
    # Encrypt the vote, for testing purposes only
    public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))
    items = item_ids.to_json
    @encrypted_payload = Base64.encode64(public_key.public_encrypt(combined_items.to_json))
  end

  def unpack
    # Check the encrypted checksum
    decrypted_vote_checksum = @@private_key.private_decrypt(Base64.decode64(@vote.encrypted_vote_checksum))
    generated_vote_checksum = @@private_key.private_decrypt(Base64.decode64(@vote.generated_vote_checksum))
    raise "Vote checksum does not match #{decrypted_vote_checksum} != #{generated_vote_checksum}" unless decrypted_vote_checksum==generated_vote_checksum

    # Decrypt the vote
    decrypted_vote = Base64.decode64(@@private_key.private_decrypt(Base64.decode64(@encrypted_payload)))

    # Convert to JSON and return
    JSON.parse(decrypted_vote)
  end

  def unpack_text_only_for_testing
    Base64.decode64(@@private_key.private_decrypt(Base64.decode64(@encrypted_payload)))
  end

  def unpack_without_encryption
    # Unpack the vote without decryption
    @encrypted_payload
  end
end