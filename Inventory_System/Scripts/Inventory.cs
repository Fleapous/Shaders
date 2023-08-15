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
    
    public void ShowItems(UIDocument uiInv, VisualTreeAsset template)
    {
        foreach (var item in items)
        {
            TemplateContainer container = AddItemToUI(template, item);
            uiInv.rootVisualElement.Q("Row").Add(container);
        }
    }

    public void HideItems(UIDocument uiInv)
    {
        uiInv.rootVisualElement.Q("Row").Clear();
    }

    private TemplateContainer AddItemToUI(VisualTreeAsset template, Item item)
    {
        var container = template.Instantiate();
        container.Q<Button>("Button").style.backgroundImage = new StyleBackground(item.ItemSprite);
        container.Q<Label>("Label").text = item.name;
        
        return container;
    }

    public void AddItem(Item item)
    {
        items.Add(item);
    }
    
}
