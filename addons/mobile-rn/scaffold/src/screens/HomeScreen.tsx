import { useQuery } from "@tanstack/react-query";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";

import { getHealth } from "../api/client";

export default function HomeScreen() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["health"],
    queryFn: getHealth,
  });

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{{PROJECT_NAME}}</Text>
      {isLoading && <ActivityIndicator />}
      {error && <Text style={styles.error}>{String(error)}</Text>}
      {data && (
        <Text style={styles.body}>
          Connected. Version {data.version} ({data.build})
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: "600",
    marginBottom: 16,
  },
  body: {
    fontSize: 16,
  },
  error: {
    color: "red",
    fontSize: 14,
  },
});
