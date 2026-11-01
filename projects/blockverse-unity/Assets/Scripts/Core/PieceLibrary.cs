namespace Blockverse {
 public enum SpecialPieceType { None, Bomb, Rainbow, Lightning }
 public sealed class PieceDefinition { public bool[,] Shape{get;} public SpecialPieceType Special{get;} public PieceDefinition(bool[,] shape,SpecialPieceType special=SpecialPieceType.None){Shape=shape;Special=special;} }
 public static class PieceLibrary {
  private static readonly bool[][,] Shapes={new bool[,]{{true}},new bool[,]{{true,true}},new bool[,]{{true,true,true}},new bool[,]{{true,true},{true,true}},new bool[,]{{true,false},{true,true}},new bool[,]{{false,true},{true,true}},new bool[,]{{true,true,true},{false,true,false}},new bool[,]{{true,false,false},{true,true,true}},new bool[,]{{false,false,true},{true,true,true}}};
  public static PieceDefinition CreateRandom(System.Random random){int roll=random.Next(100);SpecialPieceType special=roll<7?SpecialPieceType.Bomb:roll<12?SpecialPieceType.Rainbow:roll<17?SpecialPieceType.Lightning:SpecialPieceType.None;return new PieceDefinition(Shapes[random.Next(Shapes.Length)],special);}
 }
}