/datum/reagent/blood
	data = new /list(
		"donor" = null,
		"species" = SPECIES_HUMAN,
		"blood_DNA" = null,
		"blood_type" = null,
		"blood_colour" = COLOR_BLOOD_HUMAN,
		"trace_chem" = null,
		"dose_chem" = null,
		"virus2" = list(),
		"antibodies" = list(),
		"has_oxy" = 1
	)
	name = "Blood"
	reagent_state = LIQUID
	metabolism = REM * 5
	color = "#c80000"
	taste_description = "iron"
	taste_mult = 1.3
	glass_name = "tomato juice"
	glass_desc = "Are you sure this is tomato juice?"

/datum/reagent/blood/initialize_data(newdata)
	..()
	if(data && data["blood_colour"])
		color = data["blood_colour"]
	return

/datum/reagent/blood/proc/sync_to(mob/living/carbon/C)
	data["donor"] = weakref(C)
	if (!data["virus2"])
		data["virus2"] = list()
	data["virus2"] |= virus_copylist(C.virus2)
	data["antibodies"] = C.antibodies
	data["blood_DNA"] = C.dna.unique_enzymes
	data["blood_type"] = C.dna.b_type
	data["species"] = C.species.name
	data["has_oxy"] = C.species.blood_oxy
	var/list/temp_chem = list()
	for(var/datum/reagent/R in C.reagents.reagent_list)
		temp_chem[R.type] = R.volume
	data["trace_chem"] = list2params(temp_chem)
	data["dose_chem"] = list2params(C.chem_doses)
	data["blood_colour"] = C.species.get_blood_colour(C)
	color = data["blood_colour"]

/datum/reagent/blood/mix_data(newdata, newamount)
	if(!islist(newdata))
		return
	if(!data["virus2"])
		data["virus2"] = list()
	data["virus2"] |= newdata["virus2"]
	if(!data["antibodies"])
		data["antibodies"] = list()
	data["antibodies"] |= newdata["antibodies"]

/datum/reagent/antibodies/mix_data(newdata, newamount)
	if(!islist(newdata))
		return
	if(!data["antibodies"])
		data["antibodies"] = list()
	data["antibodies"] |= newdata["antibodies"]

/datum/reagent/blood/get_data() // Just in case you have a reagent that handles data differently.
	var/t = data.Copy()
	if(t["virus2"])
		var/list/v = t["virus2"]
		t["virus2"] = v.Copy()
	if(t["antibodies"])
		var/list/a = t["antibodies"]
		t["antibodies"] = a.Copy()
	return t

/datum/reagent/antibodies/get_data() // Just in case you have a reagent that handles data differently.
	var/t = data.Copy()
	if(t["antibodies"])
		var/list/v = t["antibodies"]
		t["antibodies"] = v.Copy()
	return t

/datum/reagent/blood/touch_turf(turf/simulated/T)
	if(!istype(T) || volume < 3)
		return
	var/weakref/W = data["donor"]
	if (!W)
		blood_splatter(T, src, 1)
	W = W.resolve()
	if(istype(W, /mob/living/carbon/human))
		blood_splatter(T, src, 1)
	else if(istype(W, /mob/living/carbon/alien))
		var/obj/effect/decal/cleanable/blood/B = blood_splatter(T, src, 1)
		if(B)
			B.blood_DNA["UNKNOWN DNA STRUCTURE"] = "X*"

/datum/reagent/blood/affect_ingest(mob/living/carbon/M, alien, removed)

	if(M.chem_doses[type] > 5)
		M.adjustToxLoss(removed)
	if(M.chem_doses[type] > 15)
		M.adjustToxLoss(removed)
	if(data && data["virus2"])
		var/list/vlist = data["virus2"]
		if(vlist.len)
			for(var/ID in vlist)
				var/datum/disease2/disease/V = vlist[ID]
				if(V && V.spreadtype == "Contact")
					infect_virus2(M, V.getcopy())

/datum/reagent/blood/affect_touch(mob/living/carbon/M, alien, removed)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.isSynthetic())
			return
	if(data && data["virus2"])
		var/list/vlist = data["virus2"]
		if(vlist.len)
			for(var/ID in vlist)
				var/datum/disease2/disease/V = vlist[ID]
				if(V.spreadtype == "Contact")
					infect_virus2(M, V.getcopy())
	if(data && data["antibodies"])
		M.antibodies |= data["antibodies"]

/datum/reagent/blood/affect_blood(mob/living/carbon/M, alien, removed)
	M.inject_blood(src, volume)
	remove_self(volume)

// pure concentrated antibodies
/datum/reagent/antibodies
	data = list("antibodies"=list())
	name = "Antibodies"
	taste_description = "metroid"
	reagent_state = LIQUID
	color = "#0050f0"

/datum/reagent/antibodies/affect_blood(mob/living/carbon/M, alien, removed)
	if(src.data)
		M.antibodies |= src.data["antibodies"]
	..()

#define WATER_LATENT_HEAT 19000 // How much heat is removed when applied to a hot turf, in J/unit (19000 makes 120 u of water roughly equivalent to 4L)
/datum/reagent/water
	name = "Water"
	description = "A ubiquitous chemical substance that is composed of hydrogen and oxygen."
	reagent_state = LIQUID
	color = "#0064c877"
	metabolism = REM * 10
	taste_description = "water"
	glass_name = "water"
	glass_desc = "The father of all refreshments."
	var/slippery = 1

/datum/reagent/water/affect_blood(mob/living/carbon/M, alien, removed)
	if(!istype(M, /mob/living/carbon/metroid) && alien != IS_METROID)
		return
	M.adjustToxLoss(2 * removed)

/datum/reagent/water/affect_ingest(mob/living/carbon/M, alien, removed)
	if(!istype(M, /mob/living/carbon/metroid) && alien != IS_METROID)
		return
	M.adjustToxLoss(2 * removed)

/datum/reagent/water/touch_turf(turf/simulated/T)
	if(!istype(T))
		return

	var/datum/gas_mixture/environment = T.return_air()
	var/min_temperature = T0C + 100 // 100C, the boiling point of water

	var/hotspot = (locate(/obj/fire) in T)
	if(hotspot && !istype(T, /turf/space))
		var/datum/gas_mixture/lowertemp = T.remove_air(T:air:total_moles)
		lowertemp.temperature = max(min(lowertemp.temperature-2000, lowertemp.temperature / 2), 0)
		lowertemp.react()
		T.assume_air(lowertemp)
		qdel(hotspot)

	var/flamer = (locate(/obj/flamer_fire) in T)
	if(flamer && !istype(T, /turf/space))
		qdel(flamer)

	if(environment && environment.temperature > min_temperature) // Abstracted as steam or something
		var/removed_heat = between(0, volume * WATER_LATENT_HEAT, -environment.get_thermal_energy_change(min_temperature))
		environment.add_thermal_energy(-removed_heat)
		if(prob(5))
			T.visible_message("<span class='warning'>The water sizzles as it lands on \the [T]!</span>")

	else if(volume >= 10 && slippery)
		var/turf/simulated/S = T
		S.wet_floor(1, TRUE)


/datum/reagent/water/touch_obj(obj/O)
	if(istype(O, /obj/item/reagent_containers/food/snacks/monkeycube))
		var/obj/item/reagent_containers/food/snacks/monkeycube/cube = O
		if(!cube.wrapped)
			cube.Expand()

/datum/reagent/water/touch_mob(mob/living/L, amount)
	if(istype(L))
		var/needed = L.fire_stacks * 10
		if(amount > needed)
			L.fire_stacks = 0
			L.ExtinguishMob()
			remove_self(needed)
		else
			L.adjust_fire_stacks(-(amount / 10))
			remove_self(amount)

/datum/reagent/water/affect_touch(mob/living/carbon/M, alien, removed)
	if(!istype(M, /mob/living/carbon/metroid) && alien != IS_METROID)
		return
	M.adjustToxLoss(10 * removed)	// Babies have 150 health, adults have 200; So, 15 units and 20
	var/mob/living/carbon/metroid/S = M
	if(!S.client && istype(S))
		if(S.Target) // Like cats
			S.Target = null
		if(S.Victim)
			S.Feedstop()
	if(M.chem_doses[type] == removed)
		M.visible_message("<span class='warning'>[S]'s flesh sizzles where the water touches it!</span>", "<span class='danger'>Your flesh burns in the water!</span>")
		M.confused = max(M.confused, 2)

/datum/reagent/water/firefoam
	name = "Firefighting foam"
	description = "A substance used for fire suppression. Its role is to cool the fire and to coat the fuel, preventing its contact with oxygen, resulting in suppression of the combustion."
	taste_description = "foamy dryness"
	color = "#e2e2e2"
	slippery = 0

/datum/reagent/fuel
	name = "Welding fuel"
	description = "Required for welders. Flamable."
	taste_description = "gross metal"
	reagent_state = LIQUID
	color = "#660000"
	touch_met = 5

	glass_name = "welder fuel"
	glass_desc = "Unless you are an industrial tool, this is probably not safe for consumption."

/datum/reagent/fuel/touch_turf(turf/T)
	new /obj/effect/decal/cleanable/liquid_fuel(T, volume)
	remove_self(volume)
	return

/datum/reagent/fuel/affect_blood(mob/living/carbon/M, alien, removed)
	M.adjustToxLoss(2 * removed)

/datum/reagent/fuel/touch_mob(mob/living/L, amount)
	if(istype(L))
		L.adjust_fire_stacks(amount / 10) // Splashing people with welding fuel to make them easy to ignite!

