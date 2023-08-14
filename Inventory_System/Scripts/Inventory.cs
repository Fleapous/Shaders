using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Serialization;

public class Inventory : MonoBehaviour
{
    public List<Item> items;

    private void Start()
    {
        InitItem();
    }
    
    public void GetItem()
    {
        
    }

    public void AddItem(Item item)
    {
        items.Add(item);
    }
    
    private void InitItem()
    {
        Item item1 = new Item("item1", 3, Rarity.Common);
        Item item2 = new Item("item2", 4, Rarity.Rare);
        Item item3 = new Item("item3", 33, Rarity.Legendary);

        AddItem(item1);
        AddItem(item2);
        AddItem(item3);
    }
}
