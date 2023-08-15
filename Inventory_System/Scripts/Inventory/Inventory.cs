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
            //uiInv.rootVisualElement.Add(container);
            uiInv.rootVisualElement.Q<VisualElement>(uiContainer).Add(container);
        }
    }

    public void HideItems(UIDocument uiInv, string uiContainer)
    {
        uiInv.rootVisualElement.Q(uiContainer).Clear();
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
