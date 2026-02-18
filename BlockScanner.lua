-- BlockScanner.lua (ENGLISH)
-- Scans tagged blocks and counts matches by rarity attribute.
-- Intended for YOUR OWN game.

local CollectionService = game:GetService("CollectionService")

local Scanner = {}
Scanner.__index = Scanner

export type Config = {
	MaxBlocks: number,
	Rarity: string,
	TagName: string,
	RarityAttribute: string,
}

local DEFAULT_CONFIG: Config = {
	MaxBlocks = 200,
	Rarity = "Common",
	TagName = "MineBlock",        -- Tag your blocks with this
	RarityAttribute = "Rarity",   -- Attribute on each block, e.g. "Common", "Epic", etc.
}

function Scanner.new()
	local self = setmetatable({}, Scanner)
	self.Running = false
	self.Config = table.clone(DEFAULT_CONFIG)
	self.FoundCount = 0
	self._onCountChanged = nil
	return self
end

function Scanner:SetOnCountChanged(cb: (count: number) -> ())
	self._onCountChanged = cb
end

function Scanner:SetMaxBlocks(n: number)
	n = tonumber(n) or self.Config.MaxBlocks
	self.Config.MaxBlocks = math.clamp(math.floor(n), 1, 100000)
end

function Scanner:SetRarity(rarity: string)
	if typeof(rarity) ~= "string" then return end
	self.Config.Rarity = rarity
end

function Scanner:ResetCount()
	self.FoundCount = 0
	if self._onCountChanged then
		self._onCountChanged(self.FoundCount)
	end
end

local function matchesRarity(inst: Instance, rarityAttr: string, wanted: string)
	local r = inst:GetAttribute(rarityAttr)
	return r == wanted
end

function Scanner:Start()
	if self.Running then return end
	self.Running = true
	self:ResetCount()

	task.spawn(function()
		while self.Running do
			local blocks = CollectionService:GetTagged(self.Config.TagName)

			local count = 0
			for _, block in ipairs(blocks) do
				if matchesRarity(block, self.Config.RarityAttribute, self.Config.Rarity) then
					count += 1
					if count >= self.Config.MaxBlocks then
						break
					end
				end
			end

			if count ~= self.FoundCount then
				self.FoundCount = count
				if self._onCountChanged then
					self._onCountChanged(self.FoundCount)
				end
			end

			task.wait(0.25)
		end
	end)
end

function Scanner:Stop()
	self.Running = false
end

return Scanner
