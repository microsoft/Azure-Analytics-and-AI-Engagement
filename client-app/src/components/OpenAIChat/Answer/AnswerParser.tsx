type HtmlParsedAnswer = {
  answerHtml: string;
  citations: { citation: string; index: number }[];
  followupQuestions: string[];
};

export function parseAnswer(answer: string): HtmlParsedAnswer {
  const citationsMap = new Map<string, number>();
  const followupQuestions: string[] = [];
  const citationPlaceholders: { citation: string; index: number }[] = [];
  let citationCounter = 0;

  // Extract any follow-up questions that might be in the answer
  let parsedAnswer = answer.replace(/<<([^>>]+)>>/g, (match, content) => {
    followupQuestions.push(content);
    return "";
  });

  // Trim any whitespace from the end of the answer after removing follow-up questions
  parsedAnswer = parsedAnswer.trim();

  const parts = parsedAnswer.split(/\[([^\]]+)\]/g);
  const fragments: string[] = parts.map((part, index) => {
    if (index % 2 === 0) {
      return part;
    } else {
      if (!citationsMap.has(part)) {
        citationCounter += 1;
        citationsMap.set(part, citationCounter);
      }
      const citationIndex = citationsMap.get(part);
      if (citationIndex) {
        citationPlaceholders.push({ citation: part, index: citationIndex });
      }
      return `<span id="citation-${citationIndex}" class="citation-placeholder"></span>`;
    }
  });

  const answerHtml = fragments.join("");

  return {
    answerHtml,
    citations: citationPlaceholders,
    followupQuestions,
  };
}
// import { renderToStaticMarkup } from "react-dom/server";
// import { getCitationFilePath } from "api";
// import { useContext } from "react";
// import { SettingsContext } from "context";

// type HtmlParsedAnswer = {
//   answerHtml: string;
//   citations: string[];
//   followupQuestions: string[];
// };

// export function parseAnswerToHtml(
//   answer: string,
//   endpoint: string,
//   onCitationClicked: (citationFilePath: string) => void,
//   container?: string,
//   isGMDemo?: boolean
// ): HtmlParsedAnswer {
//   const citations: string[] = [];
//   const followupQuestions: string[] = [];

//   // Extract any follow-up questions that might be in the answer
//   let parsedAnswer = answer.replace(/<<([^>>]+)>>/g, (match, content) => {
//     followupQuestions.push(content);
//     return "";
//   });

//   // trim any whitespace from the end of the answer after removing follow-up questions
//   parsedAnswer = parsedAnswer.trim();

//   const parts = parsedAnswer.split(/\[([^\]]+)\]/g);
//   const fragments: string[] = parts.map((part, index) => {
//     if (index % 2 === 0) {
//       return part;
//     } else {
//       let citationIndex: number;
//       if (citations.indexOf(part) !== -1) {
//         citationIndex = citations.indexOf(part) + 1;
//       } else {
//         citations.push(part);
//         citationIndex = citations.length;
//       }

//       const path = getCitationFilePath(part, endpoint, container, isGMDemo);
//       console.log({ path });
//       return renderToStaticMarkup(
//         <span
//           className="supContainer"
//           title={part}
//           onClick={() => {
//             alert("clicked");
//             console.log({ c: path });
//             onCitationClicked(path);
//           }}
//         >
//           <sup
//             onClick={() => {
//               alert("sub clicked");
//             }}
//           >
//             {citationIndex}
//           </sup>
//         </span>
//       );
//     }
//   });

//   return {
//     answerHtml: fragments.join(""),
//     citations,
//     followupQuestions,
//   };
// }
