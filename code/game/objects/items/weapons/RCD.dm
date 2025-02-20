//Contains the rapid construction device.

/obj/item/rcd
	name = "rapid construction device"
	desc = "Small, portable, and far, far heavier than it looks, this gun-shaped device has a port into which one may insert compressed matter cartridges."
	description_info = "On use, this device will toggle between various types of structures (or their removal). You can examine it to see its current mode. It must be loaded with compressed matter cartridges, which can be obtained from an autolathe. Click an adjacent tile to use the device."
	description_fluff = "Advents in material printing and synthesis technology have produced everyday miracles, such as the RCD, which in certain industries has single-handedly put entire construction crews out of a job."
	description_antag = "RCDs can be incredibly dangerous in the wrong hands. Use them to swiftly block off corridors, or instantly breach the ship wherever you want."
	icon = 'icons/obj/items.dmi'
	icon_state = "rcd-e"
	opacity = 0
	density = 0
	anchored = 0.0
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT|SLOT_HOLSTER
	force = 10.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 5
	w_class = ITEM_SIZE_NORMAL
	mod_weight = 1.0
	mod_reach = 0.75
	mod_handy = 1.0
	origin_tech = list(TECH_ENGINEERING = 4, TECH_MATERIAL = 2)
	matter = list(MATERIAL_STEEL = 50000)
	var/datum/effect/effect/system/spark_spread/spark_system
	var/stored_matter = 0
	var/max_stored_matter = 30

	var/work_id = 0
	var/decl/hierarchy/rcd_mode/work_mode
	var/static/list/work_modes

	var/canRwall = 0
	var/disabled = 0

/obj/item/rcd/Initialize()
	. = ..()

	if(!work_modes)
		var/decl/hierarchy/h = decls_repository.get_decl(/decl/hierarchy/rcd_mode)
		work_modes = h.children
	work_mode = work_modes[1]

/obj/item/rcd/attack()
	return 0

/obj/item/rcd/proc/can_use(mob/user,turf/T)
	return (user.Adjacent(T) && user.get_active_hand() == src && !user.incapacitated())

/obj/item/rcd/_examine_text(user)
	. = ..()
	if(src.type == /obj/item/rcd && loc == user)
		. += "\nThe current mode is '[work_mode]'"
		. += "\nIt currently holds [stored_matter]/[max_stored_matter] matter-units."

/obj/item/rcd/New()
	..()
	src.spark_system = new /datum/effect/effect/system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/item/rcd/Destroy()
	qdel(spark_system)
	spark_system = null
	return ..()

/obj/item/rcd/attackby(obj/item/W, mob/user)
	update_icon()
	if(istype(W, /obj/item/rcd_ammo))
		var/obj/item/rcd_ammo/cartridge = W
		if((stored_matter + cartridge.remaining) > 30)
			to_chat(user, "<span class='notice'>The RCD can't hold that many additional matter-units.</span>")
			return
		stored_matter += cartridge.remaining
		user.drop_from_inventory(W)
		qdel(W)
		update_icon()
		playsound(src.loc, 'sound/effects/weapons/energy/no_power1.ogg', 50, 1)
		to_chat(user, "<span class='notice'>The RCD now holds [stored_matter]/[max_stored_matter] matter-units.</span>")
		return
	..()

/obj/item/rcd/attack_self(mob/user)
	//Change the mode
	work_id++
	work_mode = next_in_list(work_mode, work_modes)
	to_chat(user, "<span class='notice'>Changed mode to '[work_mode]'</span>")
	playsound(src.loc, 'sound/effects/pop.ogg', 50, 0)
	if(prob(20)) src.spark_system.start()

/obj/item/rcd/afterattack(atom/A, mob/user, proximity)
	if(!proximity) return
	if(disabled && !isrobot(user))
		return 0
	if(istype(get_area(A),/area/shuttle)||istype(get_area(A),/turf/space/transit))
		return 0
	work_id++
	work_mode.do_work(src, A, user)

/obj/item/rcd/proc/useResource(amount, mob/user)
    if(stored_matter < amount)
        return 0
    stored_matter -= amount
    update_icon()
    return 1

/obj/item/rcd/update_icon()
	..()
	if(stored_matter > 0)
		icon_state = "rcd"
	else
		icon_state = "rcd-e"

/obj/item/rcd_ammo
	name = "compressed matter cartridge"
	desc = "A highly-compressed matter cartridge usable in rapid construction (and deconstruction) devices, such as railguns."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "rcd"
	item_state = "rcdammo"
	w_class = ITEM_SIZE_SMALL
	origin_tech = list(TECH_MATERIAL = 2)
	matter = list(MATERIAL_STEEL = 15000, MATERIAL_GLASS = 7500)
	var/remaining = 10

/obj/item/rcd_ammo/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) <= 1)
		. += "\n<span class='notice'>It has [remaining] unit\s of matter left.</span>"

/obj/item/rcd_ammo/large
	name = "high-capacity matter cartridge"
	desc = "Do not ingest."
	matter = list(MATERIAL_STEEL = 45000, MATERIAL_GLASS = 22500)
	remaining = 30
	origin_tech = list(TECH_MATERIAL = 4)

/obj/item/rcd/borg
	canRwall = 1

/obj/item/rcd/borg/useResource(amount, mob/user)
	if(isrobot(user))
		var/mob/living/silicon/robot/R = user
		if(R.cell)
			var/cost = amount*30
			if(R.cell.charge >= cost)
				R.cell.use(cost)
				return 1
	return 0

/obj/item/rcd/borg/attackby()
	return

/obj/item/rcd/borg/can_use(mob/user,turf/T)
	return (user.Adjacent(T) && !user.incapacitated())


/obj/item/rcd/mounted/useResource(amount, mob/user)
	var/cost = amount*130 //so that a rig with default powercell can build ~2.5x the stuff a fully-loaded RCD can.
	if(istype(loc,/obj/item/rig_module))
		var/obj/item/rig_module/module = loc
		if(module.holder && module.holder.cell)
			if(module.holder.cell.charge >= cost)
				module.holder.cell.use(cost)
				return 1
	return 0

/obj/item/rcd/mounted/attackby()
	return

/obj/item/rcd/mounted/can_use(mob/user,turf/T)
	return (user.Adjacent(T) && !user.incapacitated())


/decl/hierarchy/rcd_mode
	hierarchy_type = /decl/hierarchy/rcd_mode
	var/cost
	var/delay
	var/handles_type
	var/work_type

/decl/hierarchy/rcd_mode/proc/do_work(obj/item/rcd/rcd, atom/target, user)
	for(var/child in children)
		var/decl/hierarchy/rcd_mode/rcdm = child
		if(!rcdm.can_handle_work(rcd, target))
			continue
		if(!rcd.useResource(rcdm.cost, user))
			to_chat(user, "<span class='warning'>Insufficient resources.</span>")
			return FALSE

		playsound(user, 'sound/machines/click.ogg', 50, 1)
		rcdm.work_message(target, user, rcd)

		if(rcdm.delay)
			var/work_id = rcd.work_id
			if(!(do_after(user, rcdm.delay, target) && work_id == rcd.work_id && rcd.can_use(user, target) && rcdm.can_handle_work(rcd, target)))
				return FALSE

		rcdm.do_handle_work(target)
		playsound(user, 'sound/items/Deconstruct.ogg', 50, 1)
		return TRUE

	return FALSE

/decl/hierarchy/rcd_mode/proc/can_handle_work(obj/item/rcd/rcd, atom/target)
	return istype(target, handles_type)

/decl/hierarchy/rcd_mode/proc/do_handle_work(atom/target)
	var/result = get_work_result(target)
	if(ispath(result,/turf))
		var/turf/T = target
		T.ChangeTurf(result)
	else if(result)
		new result(target)
	else
		qdel(target)

/decl/hierarchy/rcd_mode/proc/get_work_result(atom/target)
	return work_type

/decl/hierarchy/rcd_mode/proc/work_message(atom/target, mob/user, rcd)
	var/message
	if(work_type)
		var/atom/work = work_type
		message = "<span class='notice'>You begin constructing \a [initial(work.name)].</span>"
	else
		message = "<span class='notice'>You begin construction.</span>"
	user.visible_message("<span class='notice'>\The [user] uses \a [rcd] to construct something.</span>", message)

/*
	Airlock construction
*/
/decl/hierarchy/rcd_mode/airlock
	name = "Airlock"

/decl/hierarchy/rcd_mode/airlock/basic
	cost = 10
	delay = 5 SECONDS
	handles_type = /turf/simulated/floor
	work_type = /obj/machinery/door/airlock

/decl/hierarchy/rcd_mode/airlock/basic/can_handle_work(rcd, turf/target)
	return ..() && !target.contains_dense_objects() && !(locate(/obj/machinery/door/airlock) in target)

/*
	Floor and Wall construction
*/
/decl/hierarchy/rcd_mode/floor_and_walls
	name = "Floor & Walls"

/decl/hierarchy/rcd_mode/floor_and_walls/base_turf
	cost = 1
	delay = 2 SECONDS
	work_type = /turf/simulated/floor/tiled

/decl/hierarchy/rcd_mode/floor_and_walls/base_turf/can_handle_work(rcd, turf/target)
	return istype(target) && (isspace(target) || istype(target, get_base_turf_by_area(target)) || isopenspace(target))

/decl/hierarchy/rcd_mode/floor_and_walls/floor_turf
	cost = 3
	delay = 2 SECONDS
	handles_type = /turf/simulated/floor
	work_type = /turf/simulated/wall

/*
	Deconstruction
*/
/decl/hierarchy/rcd_mode/deconstruction
	name = "Deconstruction"

/decl/hierarchy/rcd_mode/deconstruction/work_message(atom/target, mob/user, rcd)
	user.visible_message("<span class='warning'>\The [user] is using \a [rcd] to deconstruct \the [target]!</span>", "<span class='warning'>You are deconstructing \the [target]!</span>")

/decl/hierarchy/rcd_mode/deconstruction/airlock
	cost = 10
	delay = 5 SECONDS
	handles_type = /obj/machinery/door/airlock

/decl/hierarchy/rcd_mode/deconstruction/floor
	cost = 3
	delay = 2 SECONDS
	handles_type = /turf/simulated/floor

/decl/hierarchy/rcd_mode/deconstruction/floor/get_work_result(target)
	return get_base_turf_by_area(target)

/decl/hierarchy/rcd_mode/deconstruction/wall
	cost = 3
	delay = 2 SECONDS
	handles_type = /turf/simulated/wall
	work_type = /turf/simulated/floor

/decl/hierarchy/rcd_mode/deconstruction/wall/can_handle_work(obj/item/rcd/rcd, turf/simulated/wall/target)
	return ..() && (rcd.canRwall || !target.reinf_material)
