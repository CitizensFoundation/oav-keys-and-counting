# coding: utf-8

# Copyright (C) 2010-2016 Íbúar ses / Citizens Foundation Iceland
# Authors Robert Bjarnason, Gunnar Grimsson & Gudny Maren Valsdottir
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

class KeysController < ApplicationController

  after_filter :log_session_id

  def create_public_private_key_pair
    File.open("tempPasswordFile.txt", 'w') { |file| file.write(params[:password]) }
    output = ""
    output += `openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048 -passout file:tempPasswordFile.txt`
    success_1 = $?.success?
    output += `openssl rsa -pubout -in private_key.pem -passin file:tempPasswordFile.txt -out public_key.pem`
    success_2 = $?.success?

    if success_1 and success_2
      counting_progress = { status: keys_created }
      BudgetBallot.update(:counting_progress, counting_progress.to_s)
    end

    respond_to do |format|
      format.json { render :json => {:counting_progress => BudgetConfig.first.counting_progress, success_1: success_1, success_2: success_2 }}
    end
  end
end
