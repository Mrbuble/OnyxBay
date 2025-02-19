
/obj/machinery/vending/fitness
	name = "SweatMAX"
	desc = "An exercise aid and nutrition supplement vendor that preys on your inadequacy."
	product_slogans = "SweatMAX, get robust!"
	product_ads = "Pain is just weakness leaving the body!;Run! Your fat is catching up to you;Never forget leg day!;Push out!;This is the only break you get today.;Don't cry, sweat!;Healthy is an outfit that looks good on everybody."
	icon_state = "fitness"
	use_vend_state = TRUE
	vend_delay = 6
	rand_amount = TRUE
	products = list(/obj/item/reagent_containers/food/drinks/milk/smallcarton = 8,
					/obj/item/reagent_containers/food/drinks/milk/smallcarton/chocolate = 8,
					/obj/item/reagent_containers/food/drinks/glass2/fitnessflask/proteinshake = 8,
					/obj/item/reagent_containers/food/drinks/glass2/fitnessflask = 8,
					/obj/item/reagent_containers/food/snacks/packaged/nutribar = 8,
					/obj/item/reagent_containers/food/snacks/liquidfood = 8,
					/obj/item/reagent_containers/pill/diet = 8,
					/obj/item/towel/random = 8)

	prices = list(/obj/item/reagent_containers/food/drinks/milk/smallcarton = 3,
					/obj/item/reagent_containers/food/drinks/milk/smallcarton/chocolate = 3,
					/obj/item/reagent_containers/food/drinks/glass2/fitnessflask/proteinshake = 20,
					/obj/item/reagent_containers/food/drinks/glass2/fitnessflask = 5,
					/obj/item/reagent_containers/food/snacks/packaged/nutribar = 5,
					/obj/item/reagent_containers/food/snacks/liquidfood = 5,
					/obj/item/reagent_containers/pill/diet = 25,
					/obj/item/towel/random = 40)

	contraband = list(/obj/item/reagent_containers/syringe/steroid/packaged = 4)
