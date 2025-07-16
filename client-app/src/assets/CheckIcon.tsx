import React from 'react';

export const CheckIcon = () => {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="125"
      height="125"
      viewBox="0 0 171 171"
      fill="none"
    >
      <g filter="url(#filter0_d_601_353)">
        <circle cx="85.5" cy="85.5" r="78.5" fill="white" />
        <circle cx="85.5" cy="85.5" r="77" stroke="#2EB464" stroke-width="3" />
      </g>
      <path
        d="M49 89.0444L70.6719 111L122 59"
        stroke="#2EB464"
        stroke-width="6"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <defs>
        <filter
          id="filter0_d_601_353"
          x="0"
          y="0"
          width="171"
          height="171"
          filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB"
        >
          <feFlood flood-opacity="0" result="BackgroundImageFix" />
          <feColorMatrix
            in="SourceAlpha"
            type="matrix"
            values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0"
            result="hardAlpha"
          />
          <feOffset />
          <feGaussianBlur stdDeviation="3.5" />
          <feComposite in2="hardAlpha" operator="out" />
          <feColorMatrix
            type="matrix"
            values="0 0 0 0 0.180392 0 0 0 0 0.705882 0 0 0 0 0.392157 0 0 0 1 0"
          />
          <feBlend
            mode="normal"
            in2="BackgroundImageFix"
            result="effect1_dropShadow_601_353"
          />
          <feBlend
            mode="normal"
            in="SourceGraphic"
            in2="effect1_dropShadow_601_353"
            result="shape"
          />
        </filter>
      </defs>
    </svg>
  );
};
