#!/usr/bin/env node
import {readFileSync,writeFileSync} from 'node:fs';
import path from 'node:path';

const source=process.argv[2];
if(!source||process.argv.length!==3) throw new Error('Usage: node scripts/name-eval/report.mjs <summary.json>');
const summary=JSON.parse(readFileSync(source,'utf8'));
const methods=summary.methods;
const pct=(n,d)=>`${(100*n/d).toFixed(1)}%`;
const escape=s=>String(s??'—').replaceAll('|','\\|').replaceAll('\n',' ');
const names={baseline:'기존: LLM 전체 이름 생성',hybrid:'혼합: LLM 분류 + 규칙 음역'};
const groups={romanize:'한국어 음역',restore:'외래어 포함',branch:'지점명 포함',latin_number:'영문·숫자 포함'};
const lines=[
  '# 새로운 식당 100개: 영어 이름 생성 방식 비교',
  '',
  `실행 완료: ${summary.generated_at}. 운영 DB에는 적용하지 않았다.`,
  '',
  '동일한 실제 카탈로그 100개를 각 방식으로 3번씩 처리했다. 기존 20개 상호는 제외했다. NVIDIA `deepseek-ai/deepseek-v4.1-flash`를 사용했고 24개 요청 모두 thinking을 껐다. 25개씩 배치 처리해 총 600개 이름 응답을 평가했다.',
  '',
  '## 비교 결과',
  '',
  '| 방식 | 1회 | 2회 | 3회 | 300개 응답 기준 통과 | 3회 중 정상 후보 존재 | 다수결 정답 |',
  '|---|---:|---:|---:|---:|---:|---:|',
];
for(const [method,m] of Object.entries(methods)) lines.push(`| ${names[method]} | ${m.trial_passed[0]}/100 | ${m.trial_passed[1]}/100 | ${m.trial_passed[2]}/100 | ${m.response_passed}/${m.response_total} (${pct(m.response_passed,m.response_total)}) | ${m.best_of_three}/100 | ${m.majority_correct}/100 |`);
if(summary.post_generation_processing_corrected){
  const original=JSON.parse(readFileSync(path.join(summary.original_run,'summary.json'),'utf8'));
  lines.push('',
    '혼합 방식 수치는 처리 코드 수정 후 **동일한 원본 모델 응답을 재처리한 값**이다. 처음에는 공백 literal 조각을 잘못 거부하고, Coffee/Cafe 사전을 restore 조각에만 적용했다. 공백 조각 허용과 기존 공통 외래어 사전의 적용 범위를 수정했다. 모델 프롬프트, 사전의 항목, 허용 답은 바꾸지 않았고 추가 API 호출도 하지 않았다.',
    '',
    `수정 전 혼합 방식: 회차별 ${original.methods.hybrid.trial_passed.join('/100, ')}/100, 3회 중 정상 후보 ${original.methods.hybrid.best_of_three}/100. 초기 처리 결과는 원래 실행 디렉터리에 보존했다. 이 수정은 결과를 확인한 뒤 이루어졌으므로, 수정된 구현에 대한 완전히 새로운 검증셋 실험으로 해석해서는 안 된다.`,
  );
}
lines.push('',
  '“3회 중 정상 후보 존재”는 사전에 정한 허용 답을 사용해 고른 결과다. 새로운 상호의 정답을 모르는 상태에서 자동으로 이 정확도를 달성한다는 의미가 아니다. 다수결 정답은 같은 이름이 두 번 이상 나온 후보만 고르며, 잘못된 철자가 반복되면 실패로 계산한다.',
  '',
  '## 유형별 비교',
  '',
  '| 유형 | 장소 수 | 기존 3회 응답 기준 통과 | 혼합 3회 응답 기준 통과 | 기존 정상 후보 존재 | 혼합 정상 후보 존재 |',
  '|---|---:|---:|---:|---:|---:|',
);
for(const [g,label] of Object.entries(groups)){
  const a=methods.baseline.groups[g],b=methods.hybrid.groups[g];
  lines.push(`| ${label} | ${a.places} | ${a.correct_responses}/${a.total_responses} | ${b.correct_responses}/${b.total_responses} | ${a.best_of_three}/${a.places} | ${b.best_of_three}/${b.places} |`);
}
lines.push('',
  '## 평가 기준과 한계',
  '',
  '- 샘플은 공개된 SBIZ/PIND 카탈로그에서 상호별 한 장소를 추출했다. 고정 문자열의 MD5 순서로 한국어 후보 40개, 외래어 후보 30개, 지점명 20개, 영문·숫자 10개를 선정했다. 이름을 검토한 뒤 실제 유형은 한국어 25개, 외래어 45개, 지점명 20개, 영문·숫자 10개로 분류했다.',
  '- 허용 표기는 모든 API 호출 전에 작성·고정했다. 모델 요청에는 원문 이름만 전달하며 허용 답, 평가 그룹, 정답 목록은 넣지 않았다. 전체 100개 이름에 대한 사전 매핑을 혼합 구현에 넣지도 않았다.',
  '- 점수는 음역 우선·외래어 복원 정책에 대한 사전 허용 표기와 비교한 것이다. 100개 상호의 공식 영문명을 모두 외부 확인한 정답셋은 아니다. 출처 철자나 조각 경계가 불명확한 10개는 별도로 표시했다.',
  '- 대소문자·공백·구두점·라틴 악센트는 무시하고 `and`와 `&`는 동등하게 비교한다. 지점 위치를 보존하면 Branch 접미사 생략도 허용한다. 의미 번역으로 한국 상호를 바꾸거나 없는 글자를 더하는 것은 허용하지 않는다.',
  '- 기존 프롬프트는 이전 실험의 v2 그대로다. 혼합 방식은 LLM이 romanize/restore/literal 조각만 만들고, 한국어 조각은 `koroman@1.0.16`이 변환한다. Coffee/Cafe 등 공통 외래어 사전이 복원 철자를 보정한다. 이번 결과를 본 뒤 프롬프트나 허용 표기를 변경해 재평가하지 않았다.',
  '- 구조 검증 오류도 실패에 포함한다. 누락·추가 글자, 원문 불일치, 잘못된 조각 유형은 생성 이름으로 채택하지 않는다.',
  '',
  `허용 표기 파일 SHA-256: \`${summary.fixture_sha256}\`. reasoning 토큰 합계: **${summary.reasoning_tokens}**. 입력 ${summary.total_usage.prompt_tokens.toLocaleString()}토큰, 출력 ${summary.total_usage.completion_tokens.toLocaleString()}토큰.`,
  '',
  '[음역 라이브러리 구현과 규칙](https://github.com/gerosyab/koroman) · [국어의 로마자 표기법](https://www.law.go.kr/admRulLsInfoP.do?admRulId=28477&efYd=0)',
  '',
  '## 출처가 불명확한 10개를 제외한 결과',
  '',
);
for(const [method,m] of Object.entries(methods)) lines.push(`- ${names[method]}: 3회 중 정상 후보 ${m.clear_source_best_of_three}/${m.clear_source_total}. 구조 검증 오류 ${m.invalid_responses}/300. 다수결 후보 없음 ${m.no_consensus}/100.`);
const changes=methods.baseline.results.map((a,i)=>({a,b:methods.hybrid.results[i]}));
lines.push('','## 혼합 방식에서 정상 후보가 새로 나온 이름','');
for(const {a,b} of changes.filter(({a,b})=>!a.selected_en&&b.selected_en)) lines.push(`- ${a.ko}: 기존 ${a.candidates.map(c=>c.en??c.error).join(' / ')} → 혼합 ${b.selected_en}`);
if(!changes.some(({a,b})=>!a.selected_en&&b.selected_en)) lines.push('해당 없음.');
lines.push('','## 기존 방식만 정상 후보를 만든 이름','');
for(const {a,b} of changes.filter(({a,b})=>a.selected_en&&!b.selected_en)) lines.push(`- ${a.ko}: 기존 ${a.selected_en} → 혼합 ${b.candidates.map(c=>c.en??c.error).join(' / ')}`);
if(!changes.some(({a,b})=>a.selected_en&&!b.selected_en)) lines.push('해당 없음.');
lines.push('','## 100개 전체 결과','','| 장소 ID | 원문 | 유형 | 기존 3회 중 정상 후보 | 혼합 3회 중 정상 후보 | 출처 모호 |','|---|---|---|---|---|---|');
for(const {a,b} of changes) lines.push(`| ${a.id} | ${escape(a.ko)} | ${groups[a.group]} | ${escape(a.selected_en)} | ${escape(b.selected_en)} | ${a.ambiguous_source?'예':''} |`);
lines.push('','## 재현과 원본 응답','','```sh','npm ci --prefix scripts/name-eval --ignore-scripts','node scripts/name-eval/benchmark.mjs','node scripts/name-eval/report.mjs <실행 디렉터리>/summary.json','```','',
  `배치 평가·fixture 복사본·summary.json: \`${path.dirname(source)}\`.`,
  `원본 모델 요청·응답: \`${summary.original_run??path.dirname(source)}\`.`,
  '',
  '기존 20개 저장 스크립트는 그대로 유지했다. 이 비교 코드는 DB 쓰기 기능을 포함하지 않는다.',
);
const output=path.resolve('doc/restaurant-name-english-100.md');
writeFileSync(output,lines.join('\n')+'\n');
console.log(`Saved ${output}`);
