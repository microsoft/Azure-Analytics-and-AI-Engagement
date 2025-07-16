export const useDevice = () => {
  /* Storing user's device details in a variable*/
  let details = window.navigator.userAgent;

  /* Creating a regular expression
      containing some mobile devices keywords
      to search it in details string*/
  let regexp = /android|iphone|kindle|ipad/i;

  /* Using test() method to search regexp in details
      it returns boolean value*/
  let isDesktopDevice = !regexp.test(details);

  return { isDesktopDevice };
};
