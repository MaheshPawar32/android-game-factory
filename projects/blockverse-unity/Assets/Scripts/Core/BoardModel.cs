using System;
using System.Collections.Generic;
namespace Blockverse {
 public enum CellType { Empty=0, Normal=1, Stone=90, Ice=91, CrackedIce=92 }
 public sealed class BoardModel {
  public int Width {get;} public int Height {get;} private readonly CellType[,] cells;
  public BoardModel(int width,int height){Width=Math.Max(5,Math.Min(10,width));Height=Math.Max(5,Math.Min(10,height));cells=new CellType[Width,Height];}
  public CellType GetCell(int x,int y){if(!Inside(x,y))throw new ArgumentOutOfRangeException();return cells[x,y];}
  public bool CanPlace(bool[,] shape,int ox,int oy){for(int y=0;y<shape.GetLength(0);y++)for(int x=0;x<shape.GetLength(1);x++){if(!shape[y,x])continue;int bx=ox+x,by=oy+y;if(!Inside(bx,by)||cells[bx,by]!=CellType.Empty)return false;}return true;}
  public bool TryPlace(bool[,] shape,int ox,int oy){if(!CanPlace(shape,ox,oy))return false;for(int y=0;y<shape.GetLength(0);y++)for(int x=0;x<shape.GetLength(1);x++)if(shape[y,x])cells[ox+x,oy+y]=CellType.Normal;return true;}
  public int ClearCompletedLines(){var rows=new HashSet<int>();var cols=new HashSet<int>();for(int y=0;y<Height;y++){bool full=true;for(int x=0;x<Width;x++)full&=cells[x,y]!=CellType.Empty;if(full)rows.Add(y);}for(int x=0;x<Width;x++){bool full=true;for(int y=0;y<Height;y++)full&=cells[x,y]!=CellType.Empty;if(full)cols.Add(x);}foreach(int y in rows)for(int x=0;x<Width;x++)Damage(x,y);foreach(int x in cols)for(int y=0;y<Height;y++)Damage(x,y);return rows.Count+cols.Count;}
  public int Blast(int cx,int cy){int n=0;for(int y=cy-1;y<=cy+1;y++)for(int x=cx-1;x<=cx+1;x++)if(Inside(x,y)&&cells[x,y]!=CellType.Empty){Damage(x,y);n++;}return n;}
  public int ClearRow(int row){if(row<0||row>=Height)return 0;int n=0;for(int x=0;x<Width;x++)if(cells[x,row]!=CellType.Empty){Damage(x,row);n++;}return n;}
  public int ClearColumn(int col){if(col<0||col>=Width)return 0;int n=0;for(int y=0;y<Height;y++)if(cells[col,y]!=CellType.Empty){Damage(col,y);n++;}return n;}
  public int CountObstacles(){int n=0;foreach(CellType c in cells)if(c==CellType.Stone||c==CellType.Ice||c==CellType.CrackedIce)n++;return n;}
  public void SetObstacle(int x,int y,CellType type){if(!Inside(x,y))throw new ArgumentOutOfRangeException();if(type!=CellType.Stone&&type!=CellType.Ice)throw new ArgumentException("Only obstacle types are allowed.");if(cells[x,y]!=CellType.Empty)throw new InvalidOperationException("Cell is occupied.");cells[x,y]=type;}
  private void Damage(int x,int y){switch(cells[x,y]){case CellType.Ice:cells[x,y]=CellType.CrackedIce;break;case CellType.CrackedIce:case CellType.Stone:case CellType.Normal:cells[x,y]=CellType.Empty;break;}}
  private bool Inside(int x,int y)=>x>=0&&x<Width&&y>=0&&y<Height;
 }
}