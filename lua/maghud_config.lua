MagConf = {}

MagConf.Hunger = true	--Habilita/Desabilita o suporte para HungerMod

MagConf.Anchor = 'TL' --TL (Top Left), TR (Top Right), BL (Bottom Left), BR (Bottom Right)

--~Cores do HUD~--
MagConf.Cor={} 								--Obrigatório
MagConf.Cor.Bar={} 							--Obrigatório
MagConf.Cor.Bar.HUD={}						--Obrigatório
MagConf.Cor.HUD=Color(30,30,30,250)			--Cor do fundo do HUD
MagConf.Cor.Bar.HUD.Fundo=Color(0,0,0,220)	--Cor do fundo das barras do HUD
MagConf.Cor.Bar.HUD.HP=Color(255,75,75)		--Cor da barra de HP
MagConf.Cor.Bar.HUD.AP=Color(50,139,255)	--Cor da barra de AP
MagConf.Cor.Bar.HUD.Job=Color(0,0,0,220)	--Cor da barra de Job
MagConf.Cor.Bar.HUD.Car=Color(0,0,0,220)	--Cor da barra da Carteira
MagConf.Cor.Bar.HUD.Sal=Color(0,0,0,220)	--Cor da barra do Salário
MagConf.Cor.Bar.HUD.Hunger=Color(255,180,64)	--Cor da barra de Fome

--~Cores dos Players~--
MagConf.Cor.Bar.ENT={}						--Obrigatório
MagConf.Cor.ENT=Color(30,30,30,250)			--Cor do fundo da barra do player(alvo)
MagConf.Cor.Bar.ENT.Fundo=Color(0,0,0,220)	--Cor do fundo das barras de HP e AP do player(alvo)
MagConf.Cor.Bar.ENT.HP=Color(255,75,75)		--Cor da barra de HP do player(alvo)
MagConf.Cor.Bar.ENT.AP=Color(50,139,255)	--Cor da barra de AP do player(alvo)

--~Cores da Munição~--
MagConf.Cor.AMM={}							--Obrigatório
MagConf.Cor.AMM.Fundo=Color(30,30,30,250)	--Cor do fundo do HUD de munição
MagConf.Cor.AMM.Val=Color(210,210,0,220)	--Cor dos valores do HUD de munição
MagConf.Cor.AMM.Bar=Color(210,210,0,220)	--Cor da barra do HUD de munição
MagConf.Cor.AMM.FBar=Color(0,0,0,220)		--Cor do fundo da barra do HUD de munição

MagConf.Cor.HUNGER={}							--Obrigatório
MagConf.Cor.HUNGER.Fundo=Color(30,30,30,250)	--Cor do fundo do HUD de munição
MagConf.Cor.HUNGER.Val=Color(210,210,0,220)		--Cor dos valores do HUD de munição
MagConf.Cor.HUNGER.Bar=Color(210,210,0,220)		--Cor da barra do HUD de munição
MagConf.Cor.HUNGER.FBar=Color(0,0,0,220)		--Cor do fundo da barra do HUD de munição

--~Configurações extras~--
MagConf.Atmos = false
MagConf.Utilites = false
MagConf.Radar = false

MagConf.TextoCarteira = "Carteira"
MagConf.TextoSalario = "Salario"

--~Tabela de Armas que não possui HUD de Munição~--
MagConf.Armas_SemHUD = {
	"weapon_physcannon",
	"weapon_physgun",
	"keys",
	"pocket",
	"gmod_camera",
	"weapon_keypadchecker",
	"gmod_tool",
	"arrest_stick",
	"door_ram",
	"lockpick",
	"med_kit",
	"stunstick",
	"unarrest_stick",
	"weaponchecker",
	"weapon_crowbar",
	"weapon_stunstick",
	"weapon_bugbait",
	"weapon_fists",
	"manhack_welder",
	"laserpointer",
	"remotecontroller",
	"weapon_angryhobo",
	"weapon_gpee",
	"m9k_knife",
	"m9k_machete",
	"m9k_fists",
	"m9k_damascus",
	"weapon_keycard",
	"weapon_hacking_keycard",
	"keypad_cracker",
	"fastkeypad_cracker",
	"picareta_1",
	"picareta_2",
	"picareta_3",
	"weapon_spraymhs",
	"weapon_arc_atmcard",
	"weapon_arc_atmhack",
	"vc_repair",
	"weapon_cable_tied",
	"weapon_surrender"
}



--~Não vou me dar o trabalho de criar um arquivo novo só para isso~--
if SERVER then
	SetGlobalString( "Atmos_Time", "0:00 AM" )
	hook.Add( "Think", "Atmos_Clock", function()
		if MagConf.Atmos then
			SetGlobalString( "Atmos_Time", os.date( "%I:%M %p",(AtmosGlobal.m_Time or 0)*3600) ) 
		end
	end )
end

if CLIENT then
	hook.Add("PlayerSay", "MagHudUtilities", function(pl,tx)
		if not MagConf.Utilites then
			return
		end
		if (tx=="/a") then
			print(pl:GetPos())
			print(pl:GetAngles())
			return ""
		end
		if (tx=="/b") then
			return pl:GetActiveWeapon():GetModel()
		end
		if (tx=="/c") then
			copiar(pl:GetEyeTrace().Entity:GetModel(),pl)
			return pl:GetEyeTrace().Entity:GetModel()
		end
		if (tx=="/tab") then
			PrintTable(pl:GetEyeTrace().Entity:GetTable())
			--PrintTable(pl:GetEyeTrace().Entity:GetNWVarTable())
			return ""
		end
		if (tx=="/s") then
			local ent = pl:GetEyeTrace().Entity
			return ent:BoundingRadius().."-"..ent:GetModelRadius()
		end
		if (string.sub(tx,1,3)=="/d ") then
			if util.IsValidModel(string.sub(tx,4,string.len(tx))) then
				pl:SetModel(string.sub(tx,4,string.len(tx)))
				return ""
			end
		end
	end)
end