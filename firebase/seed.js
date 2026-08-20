import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const projectId = process.argv
  .find((argument) => argument.startsWith('--project='))
  ?.slice('--project='.length);

if (!projectId) {
  throw new Error('Usage: npm run seed -- --project=YOUR_FIREBASE_PROJECT_ID');
}

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const now = Date.now();
const minutesAgo = (minutes) => Timestamp.fromMillis(now - minutes * 60_000);
const daysAgo = (days) => Timestamp.fromMillis(now - days * 86_400_000);

// Development-only fixtures matching lib/data/dummy_transfer_cases.dart.
// No production users, secrets or service-account credentials belong here.
const leagues = {
  'premier-league': { name: 'Premier League', countryCode: 'GB', order: 1 },
  laliga: { name: 'LaLiga', countryCode: 'ES', order: 2 },
  'serie-a': { name: 'Serie A', countryCode: 'IT', order: 3 },
  bundesliga: { name: 'Bundesliga', countryCode: 'DE', order: 4 },
  'ligue-1': { name: 'Ligue 1', countryCode: 'FR', order: 5 },
};

const clubs = {
  arsenal: ['Arsenal', 'ARS', 'Premier League', 4293068307, 4278597234],
  bayern: ['Bayern', 'FCB', 'Bundesliga', 4292609325, 4278216370],
  bologna: ['Bologna', 'BOL', 'Serie A', 4288355120, 4279906133],
  brentford: ['Brentford', 'BRE', 'Premier League', 4293068307, 4294967295],
  chelsea: ['Chelsea', 'CHE', 'Premier League', 4278404756, 4278872265],
  'crystal-palace': ['Crystal Palace', 'CRY', 'Premier League', 4279977359, 4291039790],
  dortmund: ['Dortmund', 'BVB', 'Bundesliga', 4294828288, 4278190080],
  everton: ['Everton', 'EVE', 'Premier League', 4278203289, 4294967295],
  fulham: ['Fulham', 'FUL', 'Premier League', 4279308561, 4294967295],
  liverpool: ['Liverpool', 'LIV', 'Premier League', 4291301422, 4278235817],
  'man-utd': ['Man Utd', 'MUN', 'Premier League', 4292487452, 4294697250],
  marseille: ['Marseille', 'OM', 'Ligue 1', 4281315040, 4294967295],
  milan: ['Milan', 'MIL', 'Serie A', 4294641931, 4278190080],
  napoli: ['Napoli', 'NAP', 'Serie A', 4279410903, 4279975819],
  newcastle: ['Newcastle', 'NEW', 'Premier League', 4280557344, 4282496742],
  psg: ['PSG', 'PSG', 'Ligue 1', 4278206832, 4292487452],
};

const clubDocument = (id) => {
  const [name, shortCode, league, primaryColor, secondaryColor] = clubs[id];
  return {
    id,
    name,
    shortCode,
    league,
    primaryColor,
    secondaryColor,
  };
};

const sources = {
  sky: ['Sky Sports', 0.9],
  fabrizio: ['Fabrizio Romano', 0.95],
  athletic: ['The Athletic', 0.85],
  florian: ['Florian Plettenberg', 0.8],
  gianluca: ['Gianluca Di Marzio', 0.8],
  bbc: ['BBC', 0.85],
};
const sourceDocument = (id) => ({
  name: sources[id][0],
  reliability: sources[id][1],
});

const cases = [
  ['garnacho-chelsea', ['alejandro-garnacho', 'Alejandro Garnacho', '🇦🇷', 21, 'FW'], 'man-utd', 'chelsea', 'final_stage', 76, 60, 10, 'Chelseaが正式オファーを提出', ['sky', 'fabrizio', 'athletic'], [[7, 'interest', 'Chelseaが獲得候補としてリストアップ', 'sky'], [5, 'contact', '代理人との接触を開始', 'fabrizio'], [3, 'bid', 'Chelseaが€50mを提示', 'athletic'], [1, 'agreement', '選手側と個人条件で基本合意', 'fabrizio'], [0, 'final_stage', 'クラブ間交渉が最終段階へ', 'sky']]],
  ['osimhen-arsenal', ['victor-osimhen', 'Victor Osimhen', '🇳🇬', 26, 'FW'], 'napoli', 'arsenal', 'negotiation', 48, 75, 15, '選手側との交渉開始', ['fabrizio', 'gianluca'], [[6, 'interest', 'Arsenalが獲得候補として検討', 'gianluca'], [2, 'negotiation', '選手側との交渉開始', 'fabrizio']]],
  ['palhinha-bayern', ['joao-palhinha', 'João Palhinha', '🇵🇹', 29, 'MF'], 'fulham', 'bayern', 'negotiation', 32, 45, 25, 'クラブ間で条件を協議中', ['florian'], [[4, 'contact', 'Bayernが代理人と接触', 'florian'], [1, 'negotiation', 'クラブ間で条件を協議中', 'florian']]],
  ['zirkzee-milan', ['joshua-zirkzee', 'Joshua Zirkzee', '🇳🇱', 24, 'FW'], 'bologna', 'milan', 'interest', 21, 40, 30, '関心を示す複数クラブあり', ['gianluca'], [[2, 'interest', '関心を示す複数クラブあり', 'gianluca']]],
  ['olise-crystal-palace', ['michael-olise', 'Michael Olise', '🇫🇷', 22, 'MF'], 'crystal-palace', 'bayern', 'contact', 34, 55, 40, '代理人との接触を開始', ['florian', 'athletic'], [[3, 'rumour', '複数クラブが関心と報道', 'athletic'], [1, 'contact', '代理人との接触を開始', 'florian']]],
  ['branthwaite-everton', ['jarrad-branthwaite', 'Jarrad Branthwaite', '🏴', 22, 'CB'], 'everton', 'man-utd', 'rumour', 27, 50, 55, 'Man Utdが獲得候補としてリストアップ', ['bbc'], [[1, 'rumour', 'Man Utdが獲得候補としてリストアップ', 'bbc']]],
  ['bruno-guimaraes-psg', ['bruno-guimaraes', 'Bruno Guimarães', '🇧🇷', 26, 'MF'], 'newcastle', 'psg', 'negotiation', 41, 90, 70, 'PSGがリリース条項の発動を検討', ['fabrizio'], [[2, 'negotiation', 'PSGがリリース条項の発動を検討', 'fabrizio']]],
  ['toney-chelsea', ['ivan-toney', 'Ivan Toney', '🏴', 28, 'FW'], 'brentford', 'chelsea', 'interest', 35, 40, 90, 'Chelseaが獲得候補として検討', ['sky'], [[3, 'interest', 'Chelseaが獲得候補として検討', 'sky']]],
  ['kvaratskhelia-psg', ['khvicha-kvaratskhelia', 'Khvicha Kvaratskhelia', '🇬🇪', 23, 'FW'], 'napoli', 'psg', 'bid', 28, 80, 120, 'PSGが正式オファーを準備中', ['gianluca', 'fabrizio'], [[4, 'interest', 'PSGが獲得候補としてリストアップ', 'gianluca'], [1, 'bid', 'PSGが正式オファーを準備中', 'fabrizio']]],
  ['moukoko-dortmund', ['youssoufa-moukoko', 'Youssoufa Moukoko', '🇩🇪', 19, 'FW'], 'dortmund', 'marseille', 'rumour', 22, 15, 150, 'レンタル移籍の可能性が浮上', ['florian'], [[2, 'rumour', 'レンタル移籍の可能性が浮上', 'florian']]],
  ['leao-milan-psg', ['rafael-leao', 'Rafael Leão', '🇵🇹', 25, 'FW'], 'milan', 'psg', 'rumour', 19, 100, 180, 'PSGが夏の獲得候補として関心', ['gianluca'], [[1, 'rumour', 'PSGが夏の獲得候補として関心', 'gianluca']]],
  ['isak-liverpool', ['alexander-isak', 'Alexander Isak', '🇸🇪', 25, 'FW'], 'newcastle', 'liverpool', 'official', 100, 145, 200, 'Liverpool加入が正式発表', ['sky', 'fabrizio', 'bbc'], [[10, 'bid', 'Liverpoolが正式オファーを提出', 'fabrizio'], [6, 'agreement', 'クラブ間で移籍合意', 'sky'], [2, 'official', 'Liverpool加入が正式発表', 'bbc']]],
];

const batch = db.batch();
for (const [id, data] of Object.entries(leagues)) {
  batch.set(db.collection('leagues').doc(id), data, { merge: true });
}
for (const id of Object.keys(clubs)) {
  batch.set(db.collection('clubs').doc(id), clubDocument(id), { merge: true });
}
for (const [id] of Object.entries(sources)) {
  batch.set(db.collection('sources').doc(id), sourceDocument(id), { merge: true });
}

for (const item of cases) {
  const [id, player, fromClub, toClub, status, probability, fee, updatedMinutes, headline, sourceIds, timeline] = item;
  const [playerId, name, countryFlag, age, position] = player;
  // Keep imageUrl/crestUrl written by sync-assets.js when fixtures are
  // refreshed. See SPEC.md §24, §36.
  const playerDocument = { id: playerId, name, countryFlag, age, position };
  batch.set(db.collection('players').doc(playerId), playerDocument, { merge: true });
  batch.set(db.collection('transferCases').doc(id), {
    player: playerDocument,
    fromClub: clubDocument(fromClub),
    toClub: clubDocument(toClub),
    status,
    probability,
    estimatedFeeMillionsEur: fee,
    headline,
    lastUpdated: minutesAgo(updatedMinutes),
    sources: sourceIds.map(sourceDocument),
    timeline: timeline.map(([days, eventStatus, description, sourceId]) => ({
      occurredAt: daysAgo(days),
      status: eventStatus,
      description,
      source: sourceDocument(sourceId),
    })),
  }, { merge: true });
}

await batch.commit();
console.log(`Seeded ${cases.length} transfer cases into ${projectId}.`);
