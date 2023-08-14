using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Item", menuName = "Items/Item")]
public class Item : ScriptableObject
{
    public string name;
    public int smNumber;
    public Rarity rarity;
    public Sprite ItemSprite;

    public Item(string name_, int smNumber_, Rarity rarity_)
    {
        name = name_;
        smNumber = smNumber_;
        rarity = rarity_;
    }
}

public enum Rarity
{
    Common,
    Rare,
    Legendary
}