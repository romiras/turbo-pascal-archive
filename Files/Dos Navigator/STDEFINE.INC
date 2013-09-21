{.$DEFINE POTEMKIN}

{$DEFINE UUENCODE}
{$DEFINE UUDECODE}
{.$DEFINE Modem}
{$DEFINE SpreadSheet}
{$DEFINE DiskEdit}
{$DEFINE DiskFormat}
{$DEFINE DBView}
{$DEFINE PrintManager}
{$DEFINE Game}
{$DEFINE CdPlayer}
{.$DEFINE Demo}

{.$DEFINE LITE}

{$IFDEF LITE}
  {$UNDEF Modem}
  {$UNDEF SpreadSheet}
  {$UNDEF DiskEdit}
  {$UNDEF DiskFormat}
  {$UNDEF DBView}
  {$UNDEF PrintManager}
  {$UNDEF Game}
{$ENDIF}

{ Only TPW uses "WObjects"; BP 7 calls the same unit "Objects" }
{$ifdef windows}
  {$ifndef ver70}
    {$define wobjects}
  {$endif}
{$endif}