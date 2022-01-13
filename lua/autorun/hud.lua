--~Esconder os HUDs padrões~--
--
--|| (name == "DarkRP_EntityDisplay")
local hidden = {"DarkRP_LocalPlayerHUD", "DarkRP_HUD", "DarkRP_Hungermod", "DarkRP_EntityDisplay", "CHudHealth", "CHudBattery", "CHudAmmo", "CTargetID", "CHudSecondaryAmmo", "DarkRP_Agenda", "CHUDQuickInfo"}
hook.Add("HUDShouldDraw", "esconder", function(name)
	if table.HasValue(hidden, name) then return false end
end)
--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--
if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("maghud_config.lua")
	--resource.AddFile("materials/maghud/weapon.png")
	util.AddNetworkString("cop")
end
include("maghud_config.lua")

--~Variáveis de configuração~--
local Armas_SemHUD = MagConf.Armas_SemHUD
local Cor_Fundo = MagConf.Cor.HUD
local Cor_FundoE = MagConf.Cor.ENT
local Cor_FundoAF = MagConf.Cor.AMM.Fundo
local Cor_FundoAV = MagConf.Cor.AMM.Val
local Cor_FundoAB = MagConf.Cor.AMM.Bar
local Cor_FundoAFB = MagConf.Cor.AMM.FBar
local Cor_FundoH_Barras = MagConf.Cor.Bar.HUD.Fundo
local Cor_HUD_HP = MagConf.Cor.Bar.HUD.HP
local Cor_HUD_AP = MagConf.Cor.Bar.HUD.AP
local Cor_HUD_HUNGER = MagConf.Cor.Bar.HUD.Hunger
local Cor_HUD_Job = MagConf.Cor.Bar.HUD.Job
local Cor_HUD_Car = MagConf.Cor.Bar.HUD.Car
local Cor_HUD_Sal = MagConf.Cor.Bar.HUD.Sal
local Cor_FundoE_Barras = MagConf.Cor.Bar.ENT.Fundo
local Cor_ENT_HP = MagConf.Cor.Bar.ENT.HP
local Cor_ENT_AP = MagConf.Cor.Bar.ENT.AP

--~coisas úteis~--
--~Conversão do dinheiro para ficar bonito~--
local function dinheiro(num)
	local cle = GAMEMODE.Config.currencyLeft
	local moeda = GAMEMODE.Config.currency
	
	if not num then return cle and moeda.."0" or "0"..moeda end
	if num >= 1e9 then return "" end

	num = tostring(num)
	local dp = string.find(num, "%.") or #num+1

	for i=dp-4, 1, -3 do
		num = num:sub(1, i).."."..num:sub(i+1)
	end

	return cle and moeda..num or num..moeda
end
--~Função para obter o ID da cabeça no personagem~--
local function gethead(ply)
	for i=0,100 do
		if ply:GetBoneName(i)=="ValveBiped.Bip01_Head1" then
			return i
		end
	end
	return 0
end

--~Funções para HUD~--
local function StencilStart()
	render.ClearStencil()
	render.SetStencilEnable( true )
	render.SetStencilWriteMask( 1 )
	render.SetStencilTestMask( 1 )
	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS ) 	
	render.SetStencilReferenceValue( 1 )
	render.SetColorModulation( 1, 1, 1 )
end
local function StencilReplace()
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilReferenceValue(0)
end
local function StencilEnd()
	render.SetStencilEnable( false )
end
local function DrawCircle(posx, posy, radius, progress, color)
	local poly = { }
	local v = 220
	poly[1] = {x = posx, y = posy}
	for i = 0, v*progress+0.5 do
		poly[i+2] = {x = math.sin(-math.rad(i/v*360)) * radius + posx, y = math.cos(-math.rad(i/v*360)) * radius + posy}
	end
	draw.NoTexture()
	surface.SetDrawColor(color)
	surface.DrawPoly(poly)
end

--~Calcular as Barra de HP e AP~--
local function cal(bx,by,alt,dist,val,vm)
	if val<0 then
		val = 1
	end
	if val<vm and val>0 then
		val=vm
	elseif val>100 then
		val=100
	end
	dist = dist*(val/100)
	local vx=dist-alt
	local vy=alt
	if bx+vx<bx then
		vy=alt+vx
		vx=0
		alt=vy
	end
	return {{x = bx, y = by},
			{x = bx+dist, y = by},
			{x = bx+vx, y = by+alt},
			{x = bx, y = by+vy}}
end

local function calDiag(posHud, sizeHud, val, vm)
	local bx, by = posHud.bar.x, posHud.bar.y
	alt = posHud.bar.sizeY
	dist = posHud.bar.sizeX
	if val<0 then
		val = 1
	end
	if val<vm and val>0 then
		val=vm
	elseif val>100 then
		val=100
	end
	dist = dist*(val/100)
	local vx=dist-alt
	local vy=alt
	if bx+vx<bx then
		vy=alt+vx
		vx=0
	end
	return {{x = bx, y = by},
			{x = bx+dist, y = by},
			{x = bx+dist-alt, y = by+alt},
			{x = bx-alt, y = by+alt}}
end
local function cal_barra_ammo(bx,by,difx,dify,val,val2)
	local ndif=difx/val

	local dif=ndif*val2
	dif=difx-dif
	return {{x=bx+dif,y=by},
	{x=bx+difx,y=by},
	{x=bx+difx-dify,y=by+dify},
	{x=bx-dify+dif,y=by+dify}}
end

local HUDBG = {}
local HUDCLOCK = {}
local HUDHP = {}
local HUDAP = {}
local HUDHUNGER = {}
local HUDJOB = {}
local HUDWALLET = {}
local HUDSALARY = {}
local HUDLICENSE = {}
local HUDPOS = {}
local function mapBackground(posx, posy, scale, ammoX, ammoY)
	local posX = posx+50*scale
	local posY = posy-50*scale
	HUDBG = {
		{x=posX,y=posY},
		{x=posX+370*scale,y=posY},
		{x=posX+330*scale,y=posY+40*scale},
		{x=posX+245*scale,y=posY+40*scale},
		{x=posX+225*scale,y=posY+60*scale},
		{x=posX+185*scale,y=posY+60*scale},
		{x=posX+145*scale,y=posY+100*scale},
		{x=posX,y=posY+100*scale}
	}
	local it = 50 --number of iterations for more datailed circle
	for i=0, it do
		HUDBG[#HUDBG+1] = {x = math.sin(-math.rad(i/it*180)) * 50 * scale + posx, y = math.cos(-math.rad(i/it*180)) * 50 * scale + posy}
	end
	
	HUDHP = {
		{x=posX,y=posY+2*scale},
		{x=posX+365*scale,y=posY+2*scale},
		{x=posX+348*scale,y=posY+19*scale},
		{x=posX,y=posY+19*scale}
	}
	if not MagConf.Hunger then
		HUDAP = {
			{x=posX,y=posY+21*scale},
			{x=posX+346*scale,y=posY+21*scale},
			{x=posX+329*scale,y=posY+38*scale},
			{x=posX,y=posY+38*scale}
		}
	else 
		HUDAP = {
			{x=posX,y=posY+21*scale},
			{x=posX+170*scale,y=posY+21*scale},
			{x=posX+153*scale,y=posY+38*scale},
			{x=posX,y=posY+38*scale}
		}
		HUDHUNGER = {
			{x=172*scale+posX,y=posY+21*scale},
			{x=posX+346*scale,y=posY+21*scale},
			{x=posX+329*scale,y=posY+38*scale},
			{x=155*scale+posX,y=posY+38*scale}
		}
	end
	HUDJOB = {
		{x=posX,y=posY+40*scale},
		{x=posX+242*scale,y=posY+40*scale},
		{x=posX+224*scale,y=posY+58*scale},
		{x=posX,y=posY+58*scale}
	}
	HUDWALLET = {
		{x=posX,y=posY+60*scale},
		{x=posX+182*scale,y=posY+60*scale},
		{x=posX+164*scale,y=posY+78*scale},
		{x=posX,y=posY+78*scale}
	}
	HUDSALARY = {
		{x=posX,y=posY+80*scale},
		{x=posX+162*scale,y=posY+80*scale},
		{x=posX+144*scale,y=posY+98*scale},
		{x=posX,y=posY+98*scale}
	}
	HUDLICENSE = {
		{
			{x=posX+255*scale,y=posY+40*scale},
			{x=posX+292*scale,y=posY+40*scale},
			{x=posX+272*scale,y=posY+60*scale},
			{x=posX+235*scale,y=posY+60*scale}
		},
		{
			{x=posX+258*scale,y=posY+40*scale},
			{x=posX+289*scale,y=posY+40*scale},
			{x=posX+271*scale,y=posY+58*scale},
			{x=posX+240*scale,y=posY+58*scale}
		}
	}
	HUDCLOCK = {}
	HUDCLOCK[#HUDCLOCK+1] = {x = posx, y = posy}
	for j=0, it do
		HUDCLOCK[#HUDCLOCK+1] = {x = math.sin(-math.rad(j/it*360)) * 48 * scale + posx, y = math.cos(-math.rad(j/it*360)) * 48 * scale + posy}
	end

	HUDAMMO = {
		{
			{ x = ammoX, y = ammoY },
			{ x = ammoX-40*scale, y = ammoY+40*scale },
			{ x = ammoX-105*scale, y = ammoY+40*scale },
			{ x = ammoX-85*scale, y = ammoY+20*scale },
			{ x = ammoX-225*scale, y = ammoY+20*scale },
			{ x = ammoX-205*scale, y = ammoY }
		},
		{
			{ x = ammoX-220*scale, y = ammoY+18*scale },
			{ x = ammoX-204*scale, y = ammoY+2*scale },
			{ x = ammoX-67*scale, y = ammoY+2*scale },
			{ x = ammoX-83*scale, y = ammoY+18*scale }
		}
	}
	
	HUDPOS = {
		time = {x = posx, y = posy},
		hp = {
			bar = {
				x = HUDHP[1].x,
				y = HUDHP[1].y,
				sizeY = HUDHP[3].y-HUDHP[2].y,
				sizeX = HUDHP[2].x-HUDHP[1].x
			},
			value = {
				x = HUDHP[1].x + (HUDHP[2].x - HUDHP[1].x) / 2,
				y = HUDHP[2].y + (HUDHP[3].y - HUDHP[2].y) / 2
			}
		},
		ap = {
			bar = {
				x = HUDAP[1].x,
				y = HUDAP[1].y,
				sizeY = HUDAP[3].y-HUDAP[2].y,
				sizeX = HUDAP[2].x-HUDAP[1].x
			},
			value = {
				x = HUDHP[1].x + (HUDHP[2].x - HUDHP[1].x) / 2,
				y = HUDAP[2].y + (HUDAP[3].y - HUDAP[2].y) / 2
			}
		},
		job = {
			x = HUDJOB[1].x + 2*scale,
			y = HUDJOB[2].y + (HUDJOB[3].y - HUDJOB[2].y) / 2
		},
		wallet = {
			x = HUDWALLET[1].x + 2*scale,
			y = HUDWALLET[2].y + (HUDWALLET[3].y - HUDWALLET[2].y) / 2
		},
		wallet_name = {
			x = HUDWALLET[3].x + 2*scale,
			y = HUDWALLET[2].y + (HUDWALLET[3].y - HUDWALLET[2].y) / 2
		},
		salary = {
			x = HUDSALARY[1].x + 2*scale,
			y = HUDSALARY[2].y + (HUDSALARY[3].y - HUDSALARY[2].y) / 2
		},
		salary_name =  {
			x = HUDSALARY[3].x + 2 * scale,
			y = HUDSALARY[2].y + (HUDSALARY[3].y - HUDSALARY[2].y) / 2
		},
		license = {
			x = HUDLICENSE[2][4].x + ( HUDLICENSE[2][3].x - HUDLICENSE[2][4].x ) / 2,
			y = HUDLICENSE[2][1].y - scale * 3,
			sizeX = HUDLICENSE[2][2].x - HUDLICENSE[2][1].x - scale * 2,
			sizeY = HUDLICENSE[2][3].y - HUDLICENSE[2][2].y + scale * 6
		},
		clip = {
			x = HUDAMMO[1][1].x-22*scale - (HUDAMMO[1][1].x-20*scale - HUDAMMO[2][3].x) / 2,
			y = HUDAMMO[1][1].y
		},
		ammo = {
			x = HUDAMMO[1][2].x+scale - (HUDAMMO[1][2].x - HUDAMMO[1][4].x) / 2,
			y = HUDAMMO[1][2].y
		}
	}
	if MagConf.Hunger then
		HUDPOS.ap.value.x = HUDAP[1].x + (HUDAP[2].x - HUDAP[1].x) / 2
		HUDPOS.hunger = {
			bar = {
				x = HUDHUNGER[1].x,
				y = HUDHUNGER[1].y,
				sizeY = HUDHUNGER[3].y-HUDHUNGER[2].y,
				sizeX = HUDHUNGER[2].x-HUDHUNGER[1].x
			},
			value = {
				x = HUDHUNGER[1].x + (HUDHUNGER[2].x - HUDHUNGER[1].x) / 2,
				y = HUDHUNGER[2].y + (HUDHUNGER[3].y - HUDHUNGER[2].y) / 2
			}
		}
	end

	surface.CreateFont("horas",{
		font = "verdana",
		size = 19*scale,
		antialias = true,
		weight = 800
	})

	surface.CreateFont("data",{
		font = "verdana",
		size = 12*scale,
		antialias = true,
		weight = 600
	})

	surface.CreateFont("barras", {
		font = "verdana",
		size = 12*scale,
		antialias = true,
		weight = 800
	})

	surface.CreateFont("dinheiros", {
		font = "verdana",
		size = 16*scale,
		antialias = true,
		weight = 800
	})

	surface.CreateFont("job",{
		font = "verdana",
		size = 14*scale,
		antialias = true,
		weight = 800
	})

	surface.CreateFont("hunger",{
		font = "verdana",
		size = 12*scale,
		antialias = true,
		weight = 800
	})

	surface.CreateFont("ent_nome",{
		font = "verdana",
		size = 12*scale,
		antialias = true,
		weight = 600
	})

	surface.CreateFont("clip",{
		font = "verdana",
		size = 24*scale,
		antialias = true,
		weight = 400
	})

	surface.CreateFont("arma_nome",{
		font = "verdana",
		size = 12*scale,
		antialias = true,
		weight = 200
	})
end
local function calcularHud()
	local scale = GetConVar("MagHudScale"):GetFloat()
	-- local posX, posY = 50*scale+2,ScrH()-50*scale-2
	local base = MagConf.Anchor
	local posX, posY
	if base == 'TL' then
		posX = 50*scale+2
		posY = 50*scale+2
	elseif base == 'TR' then
		posX = ScrW()-419*scale-2
		posY = 50*scale + 2
	elseif base == 'BL' then
		posX = 50*scale+2
		posY = ScrH()-50*scale-2
	elseif base == 'BR' then
		posX = ScrW()-419*scale-2
		posY = ScrH()-50*scale-2
	end
	local ammoX, ammoY = ScrW()-2,ScrH()-40*scale-2	
	mapBackground(posX,posY,scale,ammoX,ammoY)
end
function PintarHud()
	local pl=LocalPlayer()
	local colors = {
		background = MagConf.Cor.HUD,
		bar = MagConf.Cor.Bar.HUD.Fundo,
		license = {
			valid = Color(69,255,52,255),
			invalid = Color(255,69,52,255)
		},
		text = {
			bright = Color(255,255,255,255),
			dark = Color(220,220,220,90)
		}
	}
	--HUD background
	draw.NoTexture()
	StencilStart()
	surface.SetDrawColor(colors.bar)
	surface.DrawPoly(HUDCLOCK)
	surface.DrawPoly(HUDHP)
	surface.DrawPoly(HUDAP)
	if MagConf.Hunger == true then
		surface.DrawPoly(HUDHUNGER)
	end
	surface.DrawPoly(HUDJOB)
	surface.DrawPoly(HUDWALLET)
	surface.DrawPoly(HUDSALARY)
	surface.DrawPoly(HUDLICENSE[2])
	StencilReplace()
	surface.SetDrawColor(colors.background)
	surface.DrawPoly(HUDBG)
	surface.DrawPoly(HUDLICENSE[1])
	StencilEnd()

	if (MagConf.Atmos) then
		draw.SimpleText(GetGlobalString( "Atmos_Time" ),"horas", HUDPOS.time.x, HUDPOS.time.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	else
		draw.SimpleText(os.date("%I:%M %p",os.time()),"horas", HUDPOS.time.x, HUDPOS.time.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM)
		draw.SimpleText(os.date("%d-%b-%Y",os.time()),"data", HUDPOS.time.x, HUDPOS.time.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
	end
	--print(pl:getDarkRPVar("Energy"))
	--HUD HP bar
	surface.SetDrawColor(Cor_HUD_HP)
	surface.DrawPoly(cal(HUDPOS.hp.bar.x,HUDPOS.hp.bar.y,HUDPOS.hp.bar.sizeY,HUDPOS.hp.bar.sizeX,pl:Health(),1))
	draw.SimpleText(pl:Health().."/100","barras", HUDPOS.hp.value.x, HUDPOS.hp.value.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	
	--HUD AP bar
	surface.SetDrawColor(Cor_HUD_AP)
	surface.DrawPoly(cal(HUDPOS.ap.bar.x,HUDPOS.ap.bar.y,HUDPOS.ap.bar.sizeY,HUDPOS.ap.bar.sizeX,pl:Armor(),1))
	draw.SimpleText(pl:Armor().."/100","barras", HUDPOS.ap.value.x, HUDPOS.ap.value.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

	if MagConf.Hunger then
		surface.SetDrawColor(Cor_HUD_HUNGER)
		surface.DrawPoly(calDiag(HUDPOS.hunger, HUDHUNGER, pl:getDarkRPVar("Energy"),1))
		draw.SimpleText(pl:getDarkRPVar("Energy").."/100","barras", HUDPOS.hunger.value.x, HUDPOS.hunger.value.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	end

	--Job name
	draw.SimpleText(pl:getDarkRPVar("job"),"job", HUDPOS.job.x, HUDPOS.job.y, colors.text.bright,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	
	--Wallet
	draw.SimpleText(MagConf.TextoCarteira,"dinheiros", HUDPOS.wallet_name.x, HUDPOS.wallet_name.y, colors.text.dark,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
	draw.SimpleText(dinheiro(pl:getDarkRPVar("money")),"dinheiros", HUDPOS.wallet.x, HUDPOS.wallet.y, colors.text.bright,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	
	--Salary
	draw.SimpleText(MagConf.TextoSalario,"dinheiros", HUDPOS.salary_name.x, HUDPOS.salary_name.y, colors.text.dark,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
	draw.SimpleText(dinheiro(pl:getDarkRPVar("salary")),"dinheiros", HUDPOS.salary.x, HUDPOS.salary.y, colors.text.bright,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

	--License
	if pl:getDarkRPVar("HasGunlicense") then
		surface.SetDrawColor(colors.license.valid)
	else
		surface.SetDrawColor(colors.license.invalid)
	end
	surface.SetMaterial(Material("fadmin/icons/weapon.vtf", "unlitgeneric"))
	surface.DrawTexturedRect(HUDPOS.license.x,HUDPOS.license.y,HUDPOS.license.sizeX,HUDPOS.license.sizeY)
	draw.NoTexture()
end
local function PintarEnt()
	local w,h = ScrW(), ScrH();
	local scale = GetConVar("MagHudScale"):GetFloat()

	local lpl = LocalPlayer()
	local trc=lpl:GetEyeTrace()

	if trc.Entity:IsPlayer() then
		local ds=trc.HitPos:Distance(trc.StartPos)
		if ds<300 then
			local ply = trc.Entity
			local pos = ply:GetBonePosition(gethead(ply)):ToScreen()
			if ds<70 then ds=ds-(70-ds)*8 end
			local x=pos.x+55-ds/11
			local y=pos.y-30+ds/30
			local pnome=ply:Name()
			surface.SetFont("ent_nome")

			local tnome=surface.GetTextSize(pnome)+4*scale
			if tnome<140*scale then tnome=140*scale end

			local Fundo_Ent = {
				{x = x-5, y = y},
				{x = x+tnome+13*scale, y = y},
				{x = x+tnome, y = y+13*scale},
				{x = x+140*scale, y = y+13*scale},
				{x = x+124*scale, y = y+29*scale},
				{x = x-5, y = y+29*scale}
			}
			
			local Fundo_EHP = {
				{x = x+30*scale, y = y+15*scale},
				{x = x+135*scale, y = y+15*scale},
				{x = x+130*scale, y = y+20*scale},
				{x = x+30*scale, y = y+20*scale}
			}
		
			local Fundo_EAP = {
				{x = x+30*scale, y = y+22*scale},
				{x = x+128*scale, y = y+22*scale},
				{x = x+123*scale, y = y+27*scale},
				{x = x+30*scale, y = y+27*scale}
			}

			draw.NoTexture()
			StencilStart()
			surface.SetDrawColor(Cor_FundoE_Barras)
			surface.DrawPoly(Fundo_EHP)
			surface.DrawPoly(Fundo_EAP)
			StencilReplace()
			surface.SetDrawColor(Cor_FundoE)
			surface.DrawPoly(Fundo_Ent)
			StencilEnd()
			surface.SetDrawColor(Cor_ENT_HP)
			surface.DrawPoly(cal(x+30*scale,y+15*scale,5*scale,105*scale,ply:Health(),3))
			surface.SetDrawColor(Cor_ENT_AP)
			surface.DrawPoly(cal(x+30*scale,y+22*scale,5*scale,100*scale,ply:Armor(),3))

			local lic = ply:getDarkRPVar("HasGunlicense")
			local Cor_lic=Color(255,69,52,150)
			if lic then
				Cor_lic=Color(69,255,52,150)
			end
			surface.SetDrawColor(Cor_lic)
			surface.SetMaterial(Material("fadmin/icons/weapon.vtf", "unlitgeneric"))
			surface.DrawTexturedRect(x+2*scale, y+8*scale, 24*scale, 24*scale)
			draw.NoTexture()

			draw.SimpleText(pnome,"ent_nome", x+1, y+1, Color(0,0,0),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
			draw.SimpleText(pnome,"ent_nome", x, y, Color(255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
		end
	end
	if IsValid(trc.Entity) and trc.Entity:isKeysOwnable() and trc.Entity:GetPos():Distance(LocalPlayer():GetPos()) < 200 then
		trc.Entity:drawOwnableInfo()
	end
end


local function PintarAmmo()
	
	-- local pl=LocalPlayer()
	-- if !IsValid(pl:GetActiveWeapon()) then return end
	-- if not (table.HasValue(Armas_SemHUD,pl:GetActiveWeapon():GetClass() or nil)) and pl:GetActiveWeapon():Clip1()>=0 then
	-- 	local colors = {
	-- 		background = MagConf.Cor.HUD,
	-- 		bar = MagConf.Cor.Bar.HUD.Fundo,
	-- 		license = {
	-- 			valid = Color(69,255,52,255),
	-- 			invalid = Color(255,69,52,255)
	-- 		},
	-- 		text = {
	-- 			bright = Color(255,255,255,255),
	-- 			dark = Color(220,220,220,90)
	-- 		}
	-- 	}

	-- 	local anm = pl:GetActiveWeapon():GetPrintName()

	-- 	local amm = pl:GetAmmoCount(pl:GetActiveWeapon():GetPrimaryAmmoType())
	-- 	local clp = pl:GetActiveWeapon():Clip1()
	-- 	local mclp= pl:GetActiveWeapon():GetMaxClip1()
	-- 	surface.SetFont("clip")
	-- 	local clps = surface.GetTextSize(clp)
	-- 	local amms = surface.GetTextSize(amm)
	-- 	surface.SetFont("arma_nome")
	-- 	local anms = surface.GetTextSize(anm)
	-- 	local maxanms = 88
	-- 	if anms<maxanms then anms=maxanms end
	-- 	anms=anms-maxanms
	-- 	local txts = clps
	-- 	if clps<amms then
	-- 		txts=amms
	-- 	end
	-- 	txts=36-txts

	-- 	local x=ScrW()-255+txts
	-- 	local y=ScrH()-45
	-- 	local scale = GetConVar("MagHudScale"):GetFloat()
	-- 	local HUDWEAPON_NAME = {
	-- 		{ x = HUDAMMO[1][4].x-5*scale, y = HUDAMMO[1][4].y+2*scale },
	-- 		{ x = HUDAMMO[1][3].x-3*scale, y = HUDAMMO[1][3].y },
	-- 		{ x = HUDAMMO[1][5].x-19*scale, y = HUDAMMO[1][3].y },
	-- 		{ x = HUDAMMO[1][5].x-1*scale, y = HUDAMMO[1][4].y+2*scale }
	-- 	}
	-- 	draw.NoTexture()
	-- 	StencilStart()
	-- 	surface.SetDrawColor(255,50,150,100)
	-- 	surface.DrawPoly(HUDAMMO[2])
	-- 	StencilReplace()
	-- 	surface.SetDrawColor(250,50,250,255)
	-- 	surface.DrawPoly(HUDAMMO[1])
	-- 	StencilEnd()
	-- 	surface.SetDrawColor(150,50,250,255)
	-- 	surface.DrawPoly(HUDWEAPON_NAME)

	-- 	-- local Muni_P = cal_barra_ammo(HUDAMMO[2][4].x,HUDAMMO[2][4].y,103*scale+anms,15*scale,mclp,clp)
	-- 	draw.SimpleText(anm,"arma_nome", HUDWEAPON_NAME[4].x, HUDWEAPON_NAME[4].y + (HUDWEAPON_NAME[3].y - HUDWEAPON_NAME[4].y) * 0.5, Cor_FundoAV,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	-- 	draw.SimpleText(clp,"clip",HUDPOS.clip.x, HUDPOS.clip.y, Cor_FundoAV,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
	-- 	draw.SimpleText(amm > 9999 and 9999 or amm,"clip", HUDPOS.ammo.x, HUDPOS.ammo.y, Cor_FundoAV,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM)
	-- end

	-- StencilStart()
	-- surface.SetDrawColor(colors.bar)
	-- surface.DrawPoly(HUDAMMO[2])
	-- StencilReplace()
	-- surface.SetDrawColor(colors.background)
	-- StencilEnd()

	--HUD HP bar
	-- surface.SetDrawColor(Cor_HUD_HP)
	-- surface.DrawPoly(cal(HUDPOS.hp.bar.x,HUDPOS.hp.bar.y,HUDPOS.hp.bar.sizeY,HUDPOS.hp.bar.sizeX,pl:Health(),1))
	-- draw.SimpleText(pl:Health().."/100","barras", HUDPOS.hp.value.x, HUDPOS.hp.value.y, colors.text.bright,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

	local w,h = ScrW(), ScrH();
	local scale = GetConVar("MagHudScale"):GetFloat()
	local pl = LocalPlayer()
	if pl:Health()<=0 then return end
	if !IsValid(pl:GetActiveWeapon()) then return end
	if not (table.HasValue(Armas_SemHUD,pl:GetActiveWeapon():GetClass() or nil)) and pl:GetActiveWeapon():Clip1()>=0 then
		
		local anm = pl:GetActiveWeapon():GetPrintName()
		local amm = pl:GetAmmoCount(pl:GetActiveWeapon():GetPrimaryAmmoType())
		local clp = pl:GetActiveWeapon():Clip1()
		local mclp= pl:GetActiveWeapon():GetMaxClip1()
		surface.SetFont("clip")
		local clps = surface.GetTextSize(clp)
		local amms = surface.GetTextSize(amm)
		surface.SetFont("arma_nome")
		local anms = surface.GetTextSize(anm)
		local maxanms = 88
		if anms<maxanms then anms=maxanms end
		anms=anms-maxanms
		local txts = clps
		if clps<amms then
			txts=amms
		end

		local x=ScrW()-255*scale+txts
		local y=ScrH()-45*scale
		
		local ammoX, ammoY = ScrW()-2,ScrH()-40*scale-2	
		local Muni_F = {
			{
				{ x = ammoX, y = ammoY },
				{ x = ammoX-40*scale, y = ammoY+40*scale },
				{ x = ammoX-78*scale-txts, y = ammoY+40*scale },
				{ x = ammoX-58*scale-txts, y = ammoY+20*scale },
				{ x = ammoX-198*scale-anms-txts, y = ammoY+20*scale },
				{ x = ammoX-178*scale-anms-txts, y = ammoY }
			},
			{
				{ x = ammoX-193*scale-anms-txts, y = ammoY+18*scale },
				{ x = ammoX-177*scale-anms-txts, y = ammoY+2*scale },
				{ x = ammoX-40*scale-txts, y = ammoY+2*scale },
				{ x = ammoX-56*scale-txts, y = ammoY+18*scale }
			}
		}
		Muni_F[3] = {
			{ x = Muni_F[1][4].x-5*scale, y = Muni_F[1][4].y+2*scale },
			{ x = Muni_F[1][3].x-3*scale, y = Muni_F[1][3].y },
			{ x = Muni_F[1][5].x-19*scale, y = Muni_F[1][3].y },
			{ x = Muni_F[1][5].x-1*scale, y = Muni_F[1][4].y+2*scale }
		}
		local Muni_P = cal_barra_ammo(Muni_F[2][2].x,Muni_F[2][2].y,Muni_F[2][3].x-Muni_F[2][2].x,Muni_F[2][2].x-Muni_F[2][1].x,mclp,clp)
		
		draw.NoTexture()
		StencilStart()
		surface.SetDrawColor(Cor_FundoAFB)
		surface.DrawPoly(Muni_F[2])
		StencilReplace()
		surface.SetDrawColor(Cor_FundoAF)
		surface.DrawPoly(Muni_F[1])
		surface.DrawPoly(Muni_F[3])
		StencilEnd()
		surface.SetDrawColor(Cor_FundoAB)
		surface.DrawPoly(Muni_P)
		
		local aux = Muni_F[1][1].x - 20*scale
		draw.SimpleText(anm,"arma_nome", Muni_F[3][4].x, Muni_F[3][4].y + (Muni_F[3][3].y - Muni_F[3][4].y) * 0.5, Cor_FundoAV,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		draw.SimpleText(clp,"clip",Muni_F[1][2].x, Muni_F[1][1].y, Cor_FundoAV,TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
		draw.SimpleText(amm,"clip", Muni_F[1][2].x, Muni_F[1][2].y, Cor_FundoAV,TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM)
	end
end
local function DrawCross(xp,yp,col)
	local thecross = {
		{{x=xp-4,y=yp+4},
		{x=xp+2,y=yp-4},
		{x=xp+4,y=yp-4},
		{x=xp-2,y=yp+4}},

		{{x=xp+4,y=yp+4},
		{x=xp+2,y=yp+4},
		{x=xp-4,y=yp-4},
		{x=xp-2,y=yp-4}}
	}
	surface.SetDrawColor(col)
	surface.DrawPoly(thecross[1])
	surface.DrawPoly(thecross[2])
end
local function PintarMapa()
	StencilStart()
	DrawCircle(ScrW() - 50, 50, 46, 1, Color(0,0,0,150))
	StencilReplace()
	DrawCircle(ScrW() - 50, 50, 49, 1, Cor_Fundo)
	StencilEnd()
	DrawCircle(ScrW() - 50, 50, 2.5, 1, Color(50,230,50))
	local pl = LocalPlayer()
	local pa = -(pl:GetAngles().Y+90)
	local pp = pl:GetPos()
	local plesf = ents.FindInSphere( pp, 430 )
	for k, v in pairs(plesf) do
		if v:IsPlayer() and v!=LocalPlayer() then
			local vp = v:GetPos()
			local distX = (vp.X - pp.X)/10
			local distY = (vp.Y - pp.Y)/10
			local ang = Angle(0,pa,0)
			local vec = Vector(distX,distY,0)
			vec:Rotate(ang)
			if Vector(0,0,0):Distance(vec)<46 then
				if v:Alive() then
					DrawCircle(ScrW() - 50 - vec.X,50 + vec.Y,2.5,4,Color(180,50,50))
				else
					DrawCross(ScrW() - 50 - vec.X,50 + vec.Y,Color(230,50,50))
				end
			end
		end
	end
end
if (CLIENT) then
	local magHudScale = CreateClientConVar( "MagHudScale", "1", true, false, "Escala para o maghud!")
	local function MagLampMenu(CPanel)
		CPanel:ClearControls()
		local panel, options, delayComboBox, fadingComboBox
		timer.Create("MagLampMenu_LoadingMenu", 0.7, 1, function()
			isMenuInitialized = true
		end)
		CPanel:AddControl("Header", {
			Description = "Personalização para o Mag HUD!"
		})

		options = {
			scale = 1
		}
		local scaleSlider = CPanel:AddControl("slider", {
			type = 'float',
			label = "Escala da HUD",
			min = 0.5,
			max = 10
		})
		scaleSlider.OnValueChanged = function(self, val)
			GetConVar("MagHudScale"):SetFloat(val)
			calcularHud()
		end
		scaleSlider:SetValue(GetConVar("MagHudScale"):GetFloat())
	end

	hook.Add("PopulateToolMenu", "PopulateSCMenu", function()
		spawnmenu.AddToolMenuOption("Utilities", "Magnum", "MagHudControl", "HUD Control", "", "", MagLampMenu)
	end)
	calcularHud()
end
hook.Add( "HUDPaint", "MagHud", function()
	if not input.IsKeyDown( KEY_TAB ) then
		PintarHud()
		PintarEnt()
		PintarAmmo()
		-- if MagConf.Radar then
		-- 	PintarMapa()
		-- end
	end
end )