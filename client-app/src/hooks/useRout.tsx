import { useLocation } from "react-router-dom";
import { useArrows } from "./useArrows";
import { useAppSelector } from "./useAppSelector";

const flowsToBeRemoved: string[] = [
  "shopping_instructions_1",
  "shopping_instructions_2",
  "customer_call_in_progress_instructions",
  "customer_call_center_instructions",
];

export const useRoute = () => {
  const location = useLocation();
  const {
    selectedDemos: { campaign, chat, shopping },
  } = useAppSelector((state) => state.config);

  const {
    routeDefinitions: { mainFlow },
  } = useArrows();
  let filteredFlow = mainFlow.filter((f) => {
    if (f === "home") {
      return true;
    }
    if (chat && f.startsWith("customer")) {
      return true;
    }

    if (shopping && f.startsWith("shopping")) {
      return true;
    }

    if (campaign && f.startsWith("campaign")) {
      return true;
    }

    return false;
  });

  if (filteredFlow?.includes("shopping_setup_wizard_persona")) {
    // Remove "shopping_setup_wizard" from the array
    const index = filteredFlow?.indexOf("customer_setup_wizard_persona");
    if (index !== -1) {
      filteredFlow?.splice(index, 1);
    }
  }

  if (filteredFlow?.includes("shopping_setup_wizard_headset")) {
    // Remove "shopping_setup_wizard" from the array
    const index = filteredFlow?.indexOf("customer_setup_wizard_headset");
    if (index !== -1) {
      filteredFlow?.splice(index, 1);
    }
  }

  if (filteredFlow?.includes("shopping_setup_wizard_microphone")) {
    // Remove "shopping_setup_wizard" from the array
    const index = filteredFlow?.indexOf("customer_setup_wizard_microphone");
    if (index !== -1) {
      filteredFlow?.splice(index, 1);
    }
  }

  const currentIndex = filteredFlow?.indexOf(
    location.pathname?.replaceAll("/", "")?.replaceAll("-", "_")
  );

  if (currentIndex !== -1) {
    const nextIndex = (currentIndex + 1) % filteredFlow?.length;
    const previousIndex =
      (currentIndex - 1 + filteredFlow?.length) % filteredFlow?.length;

    const nextRoute = `/${filteredFlow?.[nextIndex]?.replaceAll("_", "-")}`;
    const previousRoute = `/${filteredFlow?.[previousIndex]?.replaceAll(
      "_",
      "-"
    )}`;

    return { currentRoute: location.pathname, nextRoute, previousRoute };
  } else {
    // If the currentRoute is not found, or if there's an issue, return the first element.
    const defaultRoute = `/${filteredFlow?.[0]?.replaceAll("_", "-")}`;
    return {
      currentRoute: defaultRoute,
      nextRoute: defaultRoute,
      previousRoute: defaultRoute,
    };
  }
};
