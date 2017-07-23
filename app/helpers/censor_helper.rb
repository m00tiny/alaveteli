module CensorHelper
	def censor!(value)
		value.gsub!(/----- Messaggio Originale -----.*/im, '')

    value.gsub!(/^nat[oa].*CHIEDO\s*$/im,
			"[DATI PERSONALI RIMOSSI]\n\nCHIEDO\n")

    value.gsub!(/^\s*nat[oa].*?\n\s*residente a.*?\n.*?\n/im,
			"[DATI PERSONALI RIMOSSI]")
	end
end
