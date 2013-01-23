module OmniContacts
  module Importer

    autoload :Gmail, "omnicontacts/importer/gmail"
    autoload :Gapps, "omnicontacts/importer/gapps"
    autoload :Yahoo, "omnicontacts/importer/yahoo"
    autoload :Hotmail, "omnicontacts/importer/hotmail"

  end
end
