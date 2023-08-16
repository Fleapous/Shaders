using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

[CreateAssetMenu(fileName = "Item", menuName = "Items/Item")]
public class Item : ScriptableObject
{
    public string name;
    public int quantity;
    public Rarity rarity;
    public Sprite ItemSprite;

    public Item(string name_, int quantity, Rarity rarity_)
    {
        name = name_;
        this.quantity = quantity;
        rarity = rarity_;
    }
}

public enum Rarity
{
    Common,
    Rare,
    Legendary
}