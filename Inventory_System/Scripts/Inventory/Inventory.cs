using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.UIElements;

public class Inventory : MonoBehaviour
{
    public List<Item> items;
    
    public void ShowItems(UIDocument uiInv, VisualTreeAsset template, string uiContainer)
    {
        foreach (var item in items)
        {
            TemplateContainer container = AddItemToUI(template, item);
            uiInv.rootVisualElement.Q<VisualElement>(uiContainer).Add(container);
        }
        
        if (uiContainer == "RowR")
        {
            
        }
    }

    public void HideItems(UIDocument uiInv, string uiContainer)
    {
        uiInv.rootVisualElement.Q(uiContainer).Clear();
    }

    private TemplateContainer AddItemToUI(VisualTreeAsset template, Item item)
    {
        var container = template.Instantiate();
        var borderCol = GetColorForEnum(item.rarity);
        var button = container.Q<Button>("Button");
        button.style.backgroundImage = new StyleBackground(item.ItemSprite);
        button.style.borderBottomColor = borderCol;
        button.style.borderLeftColor = borderCol;
        button.style.borderRightColor = borderCol;
        button.style.borderTopColor = borderCol;
        button.clicked += () => OnButtonClick(item);
        
        container.Q<Label>("Name").text = item.name;
        container.Q<Label>("Quantity").text = item.quantity.ToString();
        
        return container;
    }
    
    private static Color GetColorForEnum(Rarity enumValue)
    {
        switch (enumValue)
        {
            case Rarity.Common:
                return Color.green;
            case Rarity.Rare:
                return Color.blue;
            case Rarity.Legendary:
                return Color.yellow;
            default:
                return Color.black;
        }
    }

    public void AddItem(Item item)
    {
        items.Add(item);
    }

    private void OnButtonClick(Item item)
    {
        //adding item transfer between 2 invs
    }
    
}
