# Firebase image assets

Place licensed images in the directories below, then publish them with
`npm run sync-assets -- --project=transfer-now-dev` from `firebase/`.

The filename (without its extension) must match the Firestore document ID.
Supported formats are `.webp`, `.png`, `.jpg`, and `.jpeg`.

## Player photos

Directory: `players/`

- `alejandro-garnacho.webp`
- `victor-osimhen.webp`
- `joao-palhinha.webp`
- `joshua-zirkzee.webp`
- `michael-olise.webp`
- `jarrad-branthwaite.webp`
- `bruno-guimaraes.webp`
- `ivan-toney.webp`
- `khvicha-kvaratskhelia.webp`
- `youssoufa-moukoko.webp`
- `rafael-leao.webp`
- `alexander-isak.webp`

Recommended: portrait or square crop, at least 512 px, WebP, under 1 MB.

## Club crests

Directory: `club-crests/`

The IDs currently used by seeded transfer cases are:

- `arsenal`, `bayern`, `bologna`, `brentford`, `chelsea`
- `crystal-palace`, `dortmund`, `everton`, `fulham`, `liverpool`
- `man-utd`, `marseille`, `milan`, `napoli`, `newcastle`, `psg`

Recommended: transparent square canvas, at least 512 px, PNG or WebP,
under 500 KB.

Only use images you created, licensed, or otherwise have permission to use.
Official club marks and editorial player photos can have separate trademark,
publicity, and copyright restrictions.

Run a local validation without uploading:

```powershell
npm run sync-assets -- --project=transfer-now-dev --dry-run
```
