local BossTab = {
    dryStreakText = nil,
    luckText = nil,
    infoButton = nil,
}

function BossTab.DrawBossInfoUI()
    local descComponent = ui.Interfaces:GetComponent(id.Component.BSLAY_BOSS_INFO__BOSS_DESC_BUILD_LAYER)
    BossTab.dryStreakText = ui.Text.new(descComponent, 1, 1)
    BossTab.dryStreakText.content = string.format("Dry streak: <col=ffffff>%d</col>", PersistentDB:GetInt("DRY_STREAK") or 0)
    BossTab.dryStreakText:SetPos(0, descComponent.height - 62)
    BossTab.dryStreakText:SetSize(descComponent.width, 20)
    BossTab.dryStreakText.font = id.Font.MUSEO_SANS_11PT_REGULAR
    BossTab.dryStreakText.colour = Vector4.new(227 / 255, 215 / 255, 207 / 255, 1)
    BossTab.dryStreakText.isShadowed = true

    BossTab.luckText = ui.Text.new(descComponent, 1, 2)
    BossTab.luckText.content = string.format("Accumulated luck: <col=ffffff>%d</col>", PersistentDB:GetInt("BLM_TRACKER") or 0)
    BossTab.luckText:SetPos(0, descComponent.height - 46)
    BossTab.luckText:SetSize(descComponent.width, 20)
    BossTab.luckText.font = id.Font.MUSEO_SANS_11PT_REGULAR
    BossTab.luckText.colour = Vector4.new(227 / 255, 215 / 255, 207 / 255, 1)
    BossTab.luckText.isShadowed = true

    BossTab.infoButton = prettyui.SpriteButton.new(descComponent, "INFO", function() end, {
        x = descComponent.width - 20,
        y = descComponent.height - 46,
        width = 16,
        height = 16,
        tooltip = "The value subtracted from the denominator when calculating drop chance."
    })
end

function BossTab.Destroy()
    if BossTab.dryStreakText then
        BossTab.dryStreakText:Destroy()
        BossTab.dryStreakText = nil
    end
    if BossTab.luckText then
        BossTab.luckText:Destroy()
        BossTab.luckText = nil
    end
    if BossTab.infoButton then
        BossTab.infoButton:Destroy()
        BossTab.infoButton = nil
    end
end

return BossTab